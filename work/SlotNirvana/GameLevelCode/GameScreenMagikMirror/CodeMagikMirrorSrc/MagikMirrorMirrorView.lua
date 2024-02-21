---
--xcyy
--2018年5月23日
--MagikMirrorMirrorView.lua
local PublicConfig = require "MagikMirrorPublicConfig"
local MagikMirrorMirrorView = class("MagikMirrorMirrorView",util_require("Levels.BaseLevelDialog"))

function MagikMirrorMirrorView:initUI()

    self:createCsbNode("MagikMirror_mojing.csb")

    self:runCsbAction("idle1") -- 播放时间线

    self.kuangList = {}

    self:addCollectKuang()

    self.freeKuang = util_createAnimation("MagikMirror_mojing_shouji.csb")
    self:showKuangForColor(self.freeKuang,true)
    self:findChild("Node_shouji_free_1"):addChild(self.freeKuang)
    self.freeKuang:setVisible(false)

    self.jackpotNode = util_createAnimation("MagikMirror_mojing_jackpot.csb")
    self:findChild("Node_jackpot"):addChild(self.jackpotNode)
    self.jackpotNode:setVisible(false)

    self.jackpotLightNode = util_createAnimation("MagikMirror_mojing_jackpot_guang.csb")
    self:findChild("Jackpotguang"):addChild(self.jackpotLightNode)
    self.jackpotLightNode:setVisible(false)

    self.image1 = util_createAnimation("MagikMirror_mojing_tubiao.csb")
    self:findChild("Node_tubiao"):addChild(self.image1)
    self.image1:setVisible(false)
end


function MagikMirrorMirrorView:addCollectKuang()
    for i=1,6 do
        local kuang = util_createAnimation("MagikMirror_mojing_shouji.csb")
        self:showKuangForColor(kuang,false)
        kuang.index = i
        kuang.isCollect = false
        self:findChild("Node_shouji_"..i):addChild(kuang)
        kuang:runCsbAction("idle1",true)
        self.kuangList[#self.kuangList + 1] = kuang
    end
end

function MagikMirrorMirrorView:showKuangForColor(node,isGold)
    if isGold then
        node:findChild("hong"):setVisible(false)
        node:findChild("jin"):setVisible(true)
    else
        node:findChild("hong"):setVisible(true)
        node:findChild("jin"):setVisible(false)
    end
end

function MagikMirrorMirrorView:initCollectKuang(num)
    for i,_kuang in ipairs(self.kuangList) do
        if not tolua.isnull(_kuang) and _kuang.index then
            _kuang.isCollect = false
            _kuang:runCsbAction("idle1",true)
        end
    end
    if num <= 0 then
        for i,_kuang in ipairs(self.kuangList) do
            if not tolua.isnull(_kuang) and _kuang.index then
                _kuang.isCollect = false
                _kuang:runCsbAction("idle1",true)
            end
        end

    else
        
        for i=1,num do
            for j,_kuang in ipairs(self.kuangList) do
                if not tolua.isnull(_kuang) and _kuang.index == i then
                    _kuang.isCollect = true
                    _kuang:runCsbAction("idle2",true)
                end
            end

        end
    end
    
    if num == 0 then
        self:findChild("m_lb_num"):setString("")
    else
        -- local newNum = 6 - num
        self:findChild("m_lb_num"):setString(num)
    end
    
end

function MagikMirrorMirrorView:initFreeCollectKuang()
    
end

function MagikMirrorMirrorView:changeImageForType(imageNode,type)
    for i=1,6 do
        local index = i - 1
        local node = imageNode:findChild("MagikMirror_"..index)
        if node then
            if index == type then
                node:setVisible(true)
            else
                node:setVisible(false)
            end
            
        end
    end
    local mirrorNode = imageNode:findChild("MagikMirror_100")
    if type == 100 then
        mirrorNode:setVisible(true)
    else
        mirrorNode:setVisible(false)
    end
    
end

--传入jackpotType,imageType，防止穿帮
function MagikMirrorMirrorView:resetCollectKuang(isShowStr,jackpotType,imageType,kuangNum)
    if jackpotType and imageType then
        self:showJackpotForIndex(jackpotType)
        self.image1:setVisible(true)
        self:changeImageForType(self.image1,imageType)
    end
    for i,_kuang in ipairs(self.kuangList) do
        if not tolua.isnull(_kuang) and _kuang.index then
            _kuang.isCollect = false
            _kuang:runCsbAction("idle1",true)
        end
    end
    self:resetImageAndJackpot()
    
    self:runCsbAction("over",false,function ()
        self.jackpotLightNode:setVisible(false)
        self:runCsbAction("idle1")
    end)
    if kuangNum then
        self:initCollectKuang(kuangNum)
    else
        if isShowStr then
            self:findChild("m_lb_num"):setVisible(false)
        else
            self:findChild("m_lb_num"):setString("")
        end
    end
    
    
end

function MagikMirrorMirrorView:resetImageAndJackpot()
    self.image1:runCsbAction("over2",false,function ()
        self.image1:setVisible(false)
    end)
    if self.jackpotNode:isVisible() then
        self.jackpotNode:runCsbAction("over2",false,function ()
            self.jackpotNode:setVisible(false)
        end)
    end
    if self.jackpotLightNode:isVisible() then
        -- self.jackpotLightNode:runCsbAction("over",false,function ()
        --     self.jackpotLightNode:setVisible(false)
        -- end)
    end
end

function MagikMirrorMirrorView:showJackpotForIndex(index)
    if index == 0 then
        self.jackpotNode:setVisible(false)
        self.jackpotLightNode:setVisible(false)
        return
    end
    self.jackpotNode:setVisible(true)
    local jackpotIndex= string.lower(index)
    self:hiteJackpotImage()
    if jackpotIndex == "grand" then
        self.jackpotNode:findChild("Node_grand"):setVisible(true)
    elseif jackpotIndex == "major" then
        self.jackpotNode:findChild("Node_major"):setVisible(true)
    elseif jackpotIndex == "minor" then
        self.jackpotNode:findChild("Node_minor"):setVisible(true)
    elseif jackpotIndex == "mini" then
        self.jackpotNode:findChild("Node_mini"):setVisible(true)
    end
    self.jackpotNode:runCsbAction("idle")
    self.jackpotLightNode:setVisible(true)
    self.jackpotLightNode:runCsbAction("idle",true)
end

function MagikMirrorMirrorView:hiteJackpotImage()
    self.jackpotNode:findChild("Node_grand"):setVisible(false)
    self.jackpotNode:findChild("Node_major"):setVisible(false)
    self.jackpotNode:findChild("Node_minor"):setVisible(false)
    self.jackpotNode:findChild("Node_mini"):setVisible(false)
end

function MagikMirrorMirrorView:updateCollectKuang(num)
    for i,_kuang in ipairs(self.kuangList) do
        if not tolua.isnull(_kuang) and _kuang.index == num then
            _kuang.isCollect = true
            _kuang:runCsbAction("shouji",false,function ()
                _kuang:runCsbAction("idle2",true)
            end)
        end
    end
    -- local newNum = 6 - num
    if num == 6 then
        self:runCsbAction("shouji2")
    else
        self:runCsbAction("shouji")
    end
    
    self:delayCallBack(15/60,function ()
        -- local newNum = 6 - num
        if num == 0 then
            self:findChild("m_lb_num"):setString("")
        else
            if num == 6 then
                print("1111")
            end
            self:findChild("m_lb_num"):setString(num)
        end
        
    end)
end

function MagikMirrorMirrorView:showOrHiteKuang(isFree)
    if isFree then
        self.freeKuang:setVisible(true)
        -- self:findChild("m_lb_num"):setString("")
        self:findChild("m_lb_num"):setVisible(false)
        for i,_kuang in ipairs(self.kuangList) do
            if not tolua.isnull(_kuang) and _kuang.index then
                _kuang:setVisible(false)
            end
        end
    else
        self.freeKuang:setVisible(false)
        self:findChild("m_lb_num"):setVisible(true)
        for i,_kuang in ipairs(self.kuangList) do
            if not tolua.isnull(_kuang) and _kuang.index then
                _kuang:setVisible(true)
            end
        end
    end
end

function MagikMirrorMirrorView:triggerRotateEffect()
    -- self:findChild("m_lb_num"):setString("")
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_Mirror_collect_fankui)
    self:runCsbAction("switch")
    util_setCascadeOpacityEnabledRescursion(self, true)
    util_setCascadeColorEnabledRescursion(self, true)
    self:delayCallBack(35/60,function ()
        local particle_4 = self:findChild("Particle_4")
        local particle_5 = self:findChild("Particle_5")
        if particle_4 and particle_5 then
            particle_4:resetSystem()
            particle_5:resetSystem()
        end
    end)
end

function MagikMirrorMirrorView:showFreeMirror(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_Mirror_change)
    self:runCsbAction("actionframe",false,function ()
        self:runCsbAction("idle1") -- 播放时间线
        if func then
            func()
        end
    end)
    self:delayCallBack(0.5,function ()
        -- self.freeKuang:setVisible(true)
        self:showOrHiteKuang(true)
    end)
end

function MagikMirrorMirrorView:updateCollectFreeKuang()
    self:runCsbAction("shouji")
    self.freeKuang:runCsbAction("shouji",false,function ()
        self.freeKuang:runCsbAction("idle2",true)
    end)
end

function MagikMirrorMirrorView:resetFreeKuang(jackpotType,imageType)
    self.freeKuang:runCsbAction("idle1",true)
    if jackpotType and imageType then
        self:showJackpotForIndex(jackpotType)
        self.image1:setVisible(true)
        self:changeImageForType(self.image1,imageType)
    end
    self:resetImageAndJackpot()
    self:runCsbAction("over",false,function ()
        self.jackpotLightNode:setVisible(false)
    end)
end

function MagikMirrorMirrorView:resetFreeKuangForFreeOver()
    self.freeKuang:runCsbAction("idle1",true)
end

--[[
    延迟回调
]]
function MagikMirrorMirrorView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return MagikMirrorMirrorView