---
--xcyy
--2018年5月23日
--MagikMirrorFreeNumBarView.lua
local PublicConfig = require "MagikMirrorPublicConfig"
local MagikMirrorFreeNumBarView = class("MagikMirrorFreeNumBarView",util_require("Levels.BaseLevelDialog"))


function MagikMirrorFreeNumBarView:initUI()

    self:createCsbNode("MagikMirror_superkuang.csb")
    self.m_lockStatus = false
    self.m_tipsStatus = false
    self.itemList = {}
    self:addCollectItem()
    -- self:findChild("Node_suoding"):setVisible(false)
    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.lighting = util_createAnimation("MagikMirror_tanban_guang.csb")
    self:findChild("Node_guang"):addChild(self.lighting)
    self.lighting:setVisible(false)

    self.tips = util_createAnimation("MagikMirror_superfree_tips.csb")
    self:findChild("Node_tips"):addChild(self.tips)
    self.tips:setVisible(false)
    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self.showNode = cc.Node:create()
    self:addChild(self.showNode)

    self.showTipsNode = cc.Node:create()
    self:addChild(self.showTipsNode)

    self:runCsbAction("idle1",true)
end

function MagikMirrorFreeNumBarView:initSpineUI()
    self.lock1 = util_spineCreate("MagikMirror_jindutiao_lock1", true, true)
    
    self.lock2 = util_spineCreate("MagikMirror_jindutiao_lock2", true, true)
    self:findChild("Node_suoding"):addChild(self.lock1,2)
    self:findChild("Node_suoding"):addChild(self.lock2,1)
    local posY = self:findChild("Node_suoding"):getPositionY()
    self:findChild("Node_suoding"):setPositionY(posY - 5)
    self.lock1:setVisible(false)
    self.lock2:setVisible(false)

end

function MagikMirrorFreeNumBarView:addCollectItem()
    for i=1,12 do
        local item = util_createAnimation("MagikMirror_super_shouji.csb")
        self:findChild("Node_"..i):addChild(item)
        self:showSpriteForIndex(item,false)
        
        self.itemList[#self.itemList + 1] = item
    end
end

function MagikMirrorFreeNumBarView:updateShowCollectItem(num)
    if num == 0 then
        return
    end
    for i=1,num do
        local item = self.itemList[i]
        if not tolua.isnull(item) then
            self:showSpriteForIndex(item,true)
        end
    end
end

function MagikMirrorFreeNumBarView:showSpriteForIndex(item,isShow)
    if isShow then
        if item.m_actName and item.m_actName ~= "idle2" then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_freeBar_addNum)
            item:runCsbAction("actionframe",false,function ()
                item.m_actName = "idle2"
                item:runCsbAction("idle2",true)
            end)
        end
    else
        item.m_actName = "idle1"
        item:runCsbAction("idle1",true)
    end
end

function MagikMirrorFreeNumBarView:showTriggerAction()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_collectBar_All)
    self:runCsbAction("actionframe",false,function ()
        self:runCsbAction("idle2",true)
    end)
    self.lighting:runCsbAction("idle2",true)
    self.lighting:setVisible(true)
end

function MagikMirrorFreeNumBarView:resetAllSprite()
    self:runCsbAction("idle1",true)
    self.lighting:setVisible(false)
    for i=1,12 do
        local item = self.itemList[i]
        if not tolua.isnull(item) then
            self:showSpriteForIndex(item,false)
        end
    end
end

function MagikMirrorFreeNumBarView:unLockCollect()
    if self.lockSound then
        gLobalSoundManager:stopAudio(self.lockSound)
        self.lockSound = nil
    end
    self.unlockSound = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_bet_unlock)
    self.showNode:stopAllActions()
    util_spinePlay(self.lock1, "unlock")
    util_spinePlay(self.lock2, "unlock")
    -- self:findChild("Button_1"):setEnabled(true)
    self.m_lockStatus = false
    performWithDelay(self.showNode,function ()
        self.lock1:setVisible(false)
        self.lock2:setVisible(false)
    end,1)
end

function MagikMirrorFreeNumBarView:lockCollect()
    if self.unlockSound then
        gLobalSoundManager:stopAudio(self.unlockSound)
        self.unlockSound = nil
    end
    self.lockSound = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_bet_lock)
    self.showNode:stopAllActions()
    self.lock1:setVisible(true)
    self.lock2:setVisible(true)
    util_spinePlay(self.lock1, "lock")
    util_spinePlay(self.lock2, "lock")
    -- self:showOverAction()
    -- self:findChild("Button_1"):setEnabled(false)
    self.m_lockStatus = true
    performWithDelay(self.showNode,function ()
        
        util_spinePlay(self.lock1, "idle1",true)
        util_spinePlay(self.lock2, "idle1",true)
    end,1)
end

--默认按钮监听回调
function MagikMirrorFreeNumBarView:clickFunc(sender)
    
    local name = sender:getName()
    if name == "Button_1" then
        self:clickBottonAction()
    elseif name == "click" then
        if self.m_lockStatus then
            gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
        end
    end
end

function MagikMirrorFreeNumBarView:clickBottonAction()
    if self.m_tipsStatus then
        self:showOverAction()
    else
        self:showAutoAction()
    end
end

function MagikMirrorFreeNumBarView:showAutoAction()
    self.showTipsNode:stopAllActions()
    self.tips:setVisible(true)
    self.m_tipsStatus = true
    self.tips:runCsbAction("auto")
    performWithDelay(self.showTipsNode,function ()
        self.m_tipsStatus = false
        self.tips:setVisible(false)
    end,3.1)
end

function MagikMirrorFreeNumBarView:showOverAction()
    self.showTipsNode:stopAllActions()
    if not self.m_tipsStatus then
        return
    end
    self.m_tipsStatus = false
    self.tips:runCsbAction("over")
    performWithDelay(self.showTipsNode,function ()
        self.tips:setVisible(false)
    end,0.5)
end

return MagikMirrorFreeNumBarView