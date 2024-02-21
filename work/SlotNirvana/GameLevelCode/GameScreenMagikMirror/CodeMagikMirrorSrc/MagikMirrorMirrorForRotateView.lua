---
--xcyy
--2018年5月23日
--MagikMirrorMirrorForRotateView.lua
local PublicConfig = require "MagikMirrorPublicConfig"
local MagikMirrorMirrorForRotateView = class("MagikMirrorMirrorForRotateView",util_require("Levels.BaseLevelDialog"))

local SHOW_ZORDER = {
    UP_ZORDER       = 100,
    DOWN_ZORDER     = 10
}

function MagikMirrorMirrorForRotateView:initUI()

    self:createCsbNode("MagikMirror_mojing.csb")

    self.isOneRotate = true

    self.isShowJackpotLight = false
    self:runCsbAction("idle2")
    local particle_2 = self:findChild("Particle_2")
    local particle_3 = self:findChild("Particle_3")
    if particle_2 and particle_3 then
        particle_2:setVisible(false)
        particle_3:setVisible(false)
    end

    local particle_4 = self:findChild("Particle_4")
    local particle_5 = self:findChild("Particle_5")
    if particle_4 and particle_5 then
        particle_4:setVisible(false)
        particle_5:setVisible(false)
    end

    self:addImageForMirror()

    self:addJackpotForNode()

    self:findChild("m_lb_num"):setVisible(false)
    self.isOverSound = false

    self.isSoundOver = false
end

function MagikMirrorMirrorForRotateView:setIsOneRotate(isOneRotate)
    self.isOneRotate = isOneRotate
end

function MagikMirrorMirrorForRotateView:showRotateEffect(lastType,type,isLast,isOverEffect)
    local particle_2 = self:findChild("Particle_2")
    local particle_3 = self:findChild("Particle_3")
    local waitTime = 25/60
    if isLast then
        waitTime = 70/60
        if type == 100 then
            
        end
        
        if isOverEffect then
            self:delayCallBack(2,function ()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_mirror_overShow)
                self.isSoundOver = true
            end)
        end
        self:runCsbAction("actionframe3")
    else
        if self.isOneRotate then
            -- self.isOneRotate = false
            self:runCsbAction("actionframe2")
            -- self:findChild("Mojing2"):setVisible(false)
        else
            self:runCsbAction("actionframe5")
        end
        
    end
    
    self:showImageChange(lastType,type)
    if self.isOneRotate then
        self.isOneRotate = false
    end
    
    self:delayCallBack(waitTime,function ()
        if particle_2 and particle_3 then
            particle_2:setVisible(true)
            particle_3:setVisible(true)
            particle_2:resetSystem()
            particle_3:resetSystem()
        end
    end)
    
    -- self:delayCallBack(55/60,function ()
    --     if self.isOneRotate then
    --         self.isOneRotate = false
    --         -- self:findChild("Mojing2"):setVisible(false)
    --     end
    -- end)
end


function MagikMirrorMirrorForRotateView:setNumVisible()
    self:findChild("Mojing2"):setVisible(false)
end

function MagikMirrorMirrorForRotateView:changeMirrorNum()
    self:findChild("m_lb_num"):setString(6)
end

--添加2个，用来旋转后转化用
function MagikMirrorMirrorForRotateView:addImageForMirror()
    self.image0 = util_createAnimation("MagikMirror_mojing_tubiao.csb")
    self:findChild("Node_tubiao"):addChild(self.image0)
    self.image0:setVisible(false)
    self.image1 = util_createAnimation("MagikMirror_mojing_tubiao.csb")
    self:findChild("Node_tubiao"):addChild(self.image1)
    self.image1:setVisible(false)
end

function MagikMirrorMirrorForRotateView:changeImageForType(imageNode,type)
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

function MagikMirrorMirrorForRotateView:setImageForType(lastType,type)
    if lastType then
        self:changeImageForType(self.image0,lastType)
        self.image0:setVisible(true)
    end
    if type then
        self:changeImageForType(self.image1,type)
        self.image1:setVisible(false)
    end
end

function MagikMirrorMirrorForRotateView:showImageChange(lastType,type)
    self:setImageForType(lastType,type)
    if not lastType then
        self.image1:setVisible(true)
        self.image1:runCsbAction("start")
        if not self.isOneRotate then
            self:changeImageForType(self.image0,100)
            self.image0:setLocalZOrder(SHOW_ZORDER.UP_ZORDER)
            self.image1:setLocalZOrder(SHOW_ZORDER.DOWN_ZORDER)
            self.image0:setVisible(true)
            self.image0:runCsbAction("over")
        end
    else
        self.image0:setLocalZOrder(SHOW_ZORDER.UP_ZORDER)
        self.image1:setLocalZOrder(SHOW_ZORDER.DOWN_ZORDER)
        self.image0:setVisible(true)
        self.image1:setVisible(true)
        self.image0:runCsbAction("over",false,function ()
            -- self.image0:setVisible(false)
        end)
        self.image1:runCsbAction("start")
    end
end

function MagikMirrorMirrorForRotateView:showImageForQuickStop(type)
    self.image0:stopAllActions()
    self.image1:stopAllActions()
    self.image0:setLocalZOrder(SHOW_ZORDER.DOWN_ZORDER)
    self.image1:setLocalZOrder(SHOW_ZORDER.UP_ZORDER)
    self.image0:setVisible(false)
    self.image1:setVisible(true)
    self.image1:runCsbAction("idle")
    self:changeImageForType(self.image1,type)
end

function MagikMirrorMirrorForRotateView:resetImageAndJackpot()
    self.image1:runCsbAction("over2")
    if self.jackpotNode:isVisible() then
        self.jackpotNode:runCsbAction("over2")
    end
end

--[[
    @desc: jackpot相关
    author:{author}
    time:2023-06-13 10:06:24
    --@time:
	--@func: 
    @return:
]]

function MagikMirrorMirrorForRotateView:addJackpotForNode()
    self.jackpotNode = util_createAnimation("MagikMirror_mojing_jackpot.csb")
    self:findChild("Node_jackpot"):addChild(self.jackpotNode)
    self.jackpotNode:setVisible(false)
    self.jackpotLighting = util_createAnimation("MagikMirror_mojing_jackpot_guang.csb")
    self:findChild("Jackpotguang"):addChild(self.jackpotLighting)
    self.jackpotLighting:setVisible(false)
end

function MagikMirrorMirrorForRotateView:showJackpotForIndex(index,isQuick)
    if index == 0 then
        if isQuick then
            self.jackpotNode:setVisible(false)
        else
            self.jackpotNode:runCsbAction("over",false,function ()
                self.jackpotNode:setVisible(false)
            end)
        end
        
        
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

    if not isQuick then
        self.jackpotNode:runCsbAction("start")
    else
        self.jackpotNode:runCsbAction("idle")
    end
    
end

function MagikMirrorMirrorForRotateView:showJackpotLightForIndex(index,isQuick,isOver)
    if index == 0 then
        if self.isShowJackpotLight then
            if isQuick then
                self.jackpotLighting:setVisible(false)
            else
                self.isShowJackpotLight = false
                self.jackpotLighting:runCsbAction("over",false,function ()
                    if not tolua.isnull(self.jackpotLighting) then
                        self.jackpotLighting:setVisible(false)
                    end
                end)
            end
        end
        
        return
    end

    self.jackpotLighting:setVisible(true)

    if not isQuick then
        self.isShowJackpotLight = true
        
        if isOver then
            self.jackpotLighting:runCsbAction("start",false,function ()
                self.jackpotLighting:runCsbAction("idle",true)
            end)
        else
            self.jackpotLighting:runCsbAction("start")
        end
    else
        self.jackpotLighting:runCsbAction("idle",true)
    end
    
end

function MagikMirrorMirrorForRotateView:hiteJackpotImage()
    self.jackpotNode:findChild("Node_grand"):setVisible(false)
    self.jackpotNode:findChild("Node_major"):setVisible(false)
    self.jackpotNode:findChild("Node_minor"):setVisible(false)
    self.jackpotNode:findChild("Node_mini"):setVisible(false)
end

function MagikMirrorMirrorForRotateView:showFlyEndAction()
    self:runCsbAction("actionframe4")
end

--[[
    延迟回调
]]
function MagikMirrorMirrorForRotateView:delayCallBack(time, func)
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

return MagikMirrorMirrorForRotateView