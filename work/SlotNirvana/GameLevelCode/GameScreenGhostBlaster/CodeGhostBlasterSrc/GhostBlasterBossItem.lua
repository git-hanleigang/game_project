---
--xcyy
--2018年5月23日
--GhostBlasterBossItem.lua
local PublicConfig = require "GhostBlasterPublicConfig"
local GhostBlasterBossItem = class("GhostBlasterBossItem",util_require("base.BaseView"))

function GhostBlasterBossItem:initUI(params)
    self.m_parentView = params.parent
    self.m_machine = params.machine

    self.m_hp = -1
    --宝箱
    self.m_boxAni = util_spineCreate("GhostBlaster_Box_boss",true,true)
    self:addChild(self.m_boxAni)
    -- self.m_boxAni:setPositionY(200)

    
    self.m_ghostAni = util_spineCreate("Socre_GhostBlaster_boss",true,true)
    self:addChild(self.m_ghostAni)

    self.m_isShowBox = false

    

    --开始飞金币节点
    self.m_coinsNodes = {}
    for index = 1,6 do
        local node = cc.Node:create()
        self:addChild(node)

        self.m_coinsNodes[index] = node

        local posX = -80 + math.floor((index - 1) / 3) * 160
        local posY = 150 + math.floor((index - 1) % 3) * 80
        node:setPosition(cc.p(posX,posY))
    end
end

--[[
    重置界面
]]
function GhostBlasterBossItem:initStatus(data)
    self.m_isNearDeath = false
    self.m_isDefeat = false
    self.m_hitCount = 0 --打击次数
    self.m_maxHitCount = data.secondRoundThreshold  --残血临界值
    self:runBossIdleAni()
end

--[[
    重置界面
]]
function GhostBlasterBossItem:resetView(data)
    self.m_isNearDeath = false
    self.m_hitCount = data.secondRoundProgress --打击次数
    self.m_maxHitCount = data.secondRoundThreshold  --残血临界值
    if data.secondRoundProgress >= data.secondRoundThreshold then
        self.m_isNearDeath = true
    end
    self:runBossIdleAni()
end

--[[
    显示boss动画
]]
function GhostBlasterBossItem:showBossAni(func)
    self.m_machine:clearCurMusicBg()
    gLobalSoundManager:playSound(PublicConfig.Music_Free_Boss_Appear)
    self.m_machine:delayCallBack(4,function()
        self.m_machine:resetMusicBg(true)
    end)
    util_spinePlay(self.m_ghostAni,"start")
    util_spineEndCallFunc(self.m_ghostAni,"start",function()
        if type(func) == "function" then
            func()
        end

        self:runBossIdleAni()
    end)

    util_spinePlay(self.m_boxAni,"start")
end


--[[
    受击动效
]]
function GhostBlasterBossItem:hitGhostAni(coins,isDefeat,isLast,func)
    self.m_hitCount  = self.m_hitCount + 1
    if self.m_hitCount >= self.m_maxHitCount then
        self.m_isNearDeath = true
    end
    if isDefeat and isLast then    --击败动效
        self:runDefeatAni(func)
        return
    end
    local aniName = "actionframe"
    if self.m_hitCount <= self.m_maxHitCount and isLast then --健康状态下的最后一击
        aniName = "actionframe_2"
    elseif self.m_hitCount == self.m_maxHitCount then --残血转换
        aniName = "actionframe2"
        gLobalSoundManager:playSound(PublicConfig.Music_Boss_ResidualBlood)
    elseif self.m_hitCount > self.m_maxHitCount and isLast then --残血状态下的最后一击
        aniName = "actionframe3_2"
        -- gLobalSoundManager:playSound(PublicConfig.Music_Boss_No_Die)
    elseif self.m_hitCount > self.m_maxHitCount then    --残血受击
        aniName = "actionframe3" 
    end
    if aniName == "actionframe" then
        local randomNum = math.random(1, 10)
        if randomNum <= 3 then
            gLobalSoundManager:playSound(PublicConfig.Music_Boss_Ahoo)
        end
    end
    gLobalSoundManager:playSound(PublicConfig.Music_Shoot_FeedBack)
    util_spinePlay(self.m_ghostAni,aniName)
    util_spineEndCallFunc(self.m_ghostAni,aniName,function()
        if isLast then
            self:runUnDefeatAni(func)
        else
            self:runBossIdleAni()
            if type(func) == "function" then
                func()
            end
        end
    end)
    local pos = util_convertToNodeSpace(self,self.m_machine.m_effectNode)
    pos.y  = pos.y + 200
    self.m_machine:hitGhostDropCoinsInFree(1,pos,true)
end

--[[
    未击败动效
]]
function GhostBlasterBossItem:runUnDefeatAni(func)
    gLobalSoundManager:playSound(PublicConfig.Music_Free_Boss_Un_Defeat)
    local aniName = "actionframe4"
    if self.m_hitCount >= self.m_maxHitCount then
        aniName = "actionframe5"
    end
    self.m_isNearDeath = false
    util_spinePlay(self.m_ghostAni,aniName)
    util_spineEndCallFunc(self.m_ghostAni,aniName,function()
        self:runBossIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    击败动画
]]
function GhostBlasterBossItem:runDefeatAni(func)

    if self.m_isDefeat then
        return
    end
    self.m_isDefeat = true
    -- util_spineMix(self.m_ghostAni,self.m_curIdleAni,"over",0.2)
    gLobalSoundManager:playSound(PublicConfig.Music_Free_Boss_Fail)
    util_spinePlay(self.m_ghostAni,"over")

    performWithDelay(self,function()
        --宝箱打开
        util_spinePlay(self.m_boxAni,"actionframe")
        util_spineEndCallFunc(self.m_boxAni,"actionframe")

        --jackpot高亮
        self.m_machine.m_jackPotBarView:hitJackpotLightAni()

        performWithDelay(self.m_boxAni,function()
            self.m_machine:showJackpotView(function()
                if type(func) == "function" then
                    func()
                end
            end)
        end,40 / 30)
    end,80 / 30)
end

--[[
    idle
]]
function GhostBlasterBossItem:runBossIdleAni()
    local randIndex = math.random(1,2)
    if self.m_machine.m_isLastBonusInFree then
        randIndex = 1
    end
    local idleAni  = "idle"
    if self.m_isNearDeath then
        idleAni  = "idle"..(randIndex + 2)
    else
        if randIndex == 2 then
            idleAni = "idle2"
        end
    end

    self.m_curIdleAni = idleAni

    util_spinePlay(self.m_ghostAni,idleAni)
    util_spineEndCallFunc(self.m_ghostAni,idleAni,function()
        self:runBossIdleAni()
    end)
end

--[[
    获取飞金币起点
]]
function GhostBlasterBossItem:getFlyNode(index)
    while index > #self.m_coinsNodes do
        index = index - #self.m_coinsNodes
    end

    return self.m_coinsNodes[index]
end

return GhostBlasterBossItem