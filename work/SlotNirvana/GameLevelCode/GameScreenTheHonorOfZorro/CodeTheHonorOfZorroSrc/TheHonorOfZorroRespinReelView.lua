---
--xcyy
--2018年5月23日
--TheHonorOfZorroRespinReelView.lua
local PublicConfig = require "TheHonorOfZorroPublicConfig"
local TheHonorOfZorroRespinReelView = class("TheHonorOfZorroRespinReelView",util_require("Levels.BaseLevelDialog"))


function TheHonorOfZorroRespinReelView:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("TheHonorOfZorro/RespinScreenTheHonorOfZorro.csb")
    self.m_unlockIndex = 1

    --jackpot
    self.m_jackpotBar = util_createView("CodeTheHonorOfZorroSrc.TheHonorOfZorroRespinJackPotBar",{machine = self.m_machine})
    self:findChild("Node_respin_jackpot"):addChild(self.m_jackpotBar)

    --respinBar
    self.m_respinbar = util_createView("CodeTheHonorOfZorroSrc.TheHonorOfZorroRespinBar",{machine = self.m_machine})
    self:findChild("Node_respinbar"):addChild(self.m_respinbar)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_respinbar"),true)

    --锁定条
    self.m_lockItems = {}
    for index = 1,4 do
        local item = util_createAnimation("TheHonorOfZorro_respin_lock.csb")
        self:findChild("Node_respin_lock_"..index):addChild(item)
        self.m_lockItems[index] = item
        item.m_leftCount = 0
        item.m_lockStatus = "lock"
    end

    --respin背景
    self.m_bgNodes = {}
    for iCol = 1,self.m_machine.m_iReelColumnNum do
        for iRow = 1,8 do
            local reelNode = self:findChild("sp_reel_"..(iCol - 1))
            local reelSize = reelNode:getContentSize()
            local slotWidth = reelSize.width
            local slotHeight = reelSize.height / 8

            local bgNode = util_createAnimation("TheHonorOfZorro_respin_di.csb")
            self:findChild("Node_sp_reel"):addChild(bgNode, 1)
            bgNode:setPosition(cc.p(reelNode:getPositionX() + slotWidth / 2,reelNode:getPositionY() + (iRow - 1) * slotHeight + slotHeight / 2))
            self.m_bgNodes[#self.m_bgNodes + 1] = bgNode
            bgNode:setVisible(false)
        end
    end
    
end

function TheHonorOfZorroRespinReelView:getRespinReelPos(col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

--[[
    刷新respin次数
]]
function TheHonorOfZorroRespinReelView:updateRespinCount(count,isInit)
    self.m_respinbar:updateCount(count,isInit)
end

--[[
    刷新锁定条
]]
function TheHonorOfZorroRespinReelView:refreshLockBarInfo(unlockRequire,statusData,isInit)
    if not unlockRequire or not statusData then
        return
    end
    local isRunUnlockAni = false
    local isChangLockNum = false
    for index = 1,4 do
        local item = self.m_lockItems[index]
        local unLockCount = unlockRequire[5 - index] or 0
        local status = statusData[5 - index] or "lock"
        --解锁动画
        local isUnLock = false
        if not isInit and item.m_lockStatus ~= status and status == "unlock" then
            isUnLock = true
            isRunUnlockAni = true
        end
        
        if isInit then
            item:setVisible(false)
        else
            if not isUnLock then
                item:setVisible(status == "lock")
            else
                item:setVisible(true)
            end
        end
        
        item.m_lockStatus = status

        --刷新剩余数量
        if unLockCount < item.m_leftCount then
            isChangLockNum = true
            item:runCsbAction("actionframe",false,function()
                if isUnLock then
                    self:unLockAni(item)
                end
            end)
        end
        item.m_leftCount = unLockCount
        item:findChild("m_lb_num"):setString(unLockCount)
    end
    if isChangLockNum then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_chang_lock_node_num)
    end

    if isRunUnlockAni then
        self.m_machine:delayCallBack(50 / 60,function()
            self.m_unlockIndex = self.m_unlockIndex + 1
            if self.m_unlockIndex > 3 then
                self.m_unlockIndex = 1
            end

            local soundName = PublicConfig.SoundConfig["sound_TheHonorOfZorro_unlock_row_reel_"..self.m_unlockIndex] 
            gLobalSoundManager:playSound(soundName)
        end)
    end
    

    return isRunUnlockAni
end

--[[
    解锁动画
]]
function TheHonorOfZorroRespinReelView:unLockAni(lockItem)
    if tolua.isnull(lockItem) then
        return
    end
    

    lockItem:runCsbAction("over",false,function()
        if not tolua.isnull(lockItem) then
            lockItem:setVisible(false)
            return
        end
    end)
    for index = 1,8 do
        local particle = lockItem:findChild("Particle_"..index)
        if particle then
            particle:resetSystem()
        end
    end
end

--[[
    锁定行动画
]]
function TheHonorOfZorroRespinReelView:showLockAni(lockStatus,func)
    if not lockStatus then
        if type(func) == "function" then
            func()
        end
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_show_respin_lock_node)

    --锁定动画,从上到下依次显示
    for index = 1,4 do
        local item = self.m_lockItems[index]
        local status = lockStatus[5 - index] or "lock"
        if status == "lock" then
            self.m_machine:delayCallBack((10 / 60) * (4 - index),function()
                item:setVisible(true)
                item:runCsbAction("suoding")
            end)
        end
        
    end

    self.m_machine:delayCallBack(1,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示动画
]]
function TheHonorOfZorroRespinReelView:showViewAni(lockStatus,keyFunc,endfunc)
    self.m_unlockIndex = 1
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_change_respin_reel)
    self:runCsbAction("actionframe")
    self.m_respinbar:setVisible(true)
    self.m_respinbar:runCsbAction("start",false,function()
        self.m_respinbar:runCsbAction("idle")
    end)

    self.m_machine:delayCallBack(1,function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_show_respin_node)
    end)

    self.m_machine:delayCallBack(130 / 60,function()
        if type(keyFunc) =="function" then
            keyFunc()
        end
        self:showLockAni(lockStatus,endfunc)
    end)
end

function TheHonorOfZorroRespinReelView:resetView()
    for index = 1,#self.m_bgNodes do
        local bgNode = self.m_bgNodes[index]
        bgNode:setVisible(false)
    end
    self.m_respinbar:setVisible(false)
    self:runCsbAction("idle1")
end

function TheHonorOfZorroRespinReelView:getReelPos(col)

    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

--[[
    渐隐出现
]]
function TheHonorOfZorroRespinReelView:runFadeAni(func)
    -- self:runCsbAction("actionframe2",false,function()
    --     if type(func) =="function" then
    --         func()
    --     end
    -- end)

    for index = 1,#self.m_bgNodes do
        local bgNode = self.m_bgNodes[index]
        bgNode:setVisible(true)
        bgNode:findChild("sp_bg_2"):setVisible(true)
        util_nodeFadeIn(bgNode,0.5,0,255)
    end
    self.m_machine:delayCallBack(0.5,function()
        for index = 1,#self.m_bgNodes do
            local bgNode = self.m_bgNodes[index]
            bgNode:findChild("sp_bg_2"):setVisible(false)
        end
    end)
end

return TheHonorOfZorroRespinReelView