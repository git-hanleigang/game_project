---
--smy
--2018年5月24日
--CrazyBombFeatureChooseView.lua
-- local BaseGame=util_require("base.BaseSimpleGame")
local SendDataManager = require "network.SendDataManager"
local CrazyBombFeatureChooseView = class("CrazyBombFeatureChooseView",util_require("base.BaseView"))
CrazyBombFeatureChooseView.m_choseFsCallFun = nil
CrazyBombFeatureChooseView.m_choseRespinCallFun = nil
CrazyBombFeatureChooseView.m_dropPig = nil
CrazyBombFeatureChooseView.m_isTouch = nil

function CrazyBombFeatureChooseView:initUI()
    self.m_featureChooseIdx = 0
    self.m_schDelay1 = false
    local isAutoScale = false
    if display.width/display.width < 1220/768  then
        isAutoScale = true
    end
    self:createCsbNode("CrazyBomb/GameChoose.csb",isAutoScale)
    local respin = self:findChild("btnRespin")
    self:addClick(respin)
    local freespin = self:findChild("btnFreespin")
    self:addClick(freespin)

    -- self.m_dropPig = util_spineCreateDifferentPath("CrazyBomb_Spine_Guochang", "CrazyBomb_Spine_chip", true, true)
    -- util_spinePlay(self.m_dropPig, "actionframe", false)
    -- -- self.m_dropPig:setScale(2)
    -- self:findChild("root"):addChild(self.m_dropPig,100)
    -- -- self.m_dropPig:setPosition(cc.p(-830, -400))
    -- util_spineEndCallFunc(self.m_dropPig, "actionframe", function()
    --     self:runCsbAction("start", false, function()
    --         if self.m_schDelay1 == false then
    --             self:runCsbAction("idle", true)
    --         end
    --     end)
    --     gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_show_choose_layer.mp3") 
    -- end)

    for i = 1, 2, 1 do
        for j = 1, 4, 1 do
            local particle = util_getChildByName(self, "Particle_"..j.."_"..(i - 1))
            particle:setVisible(false)
        end
    end

    performWithDelay(self, function ()
        self:runCsbAction("start", false, function()
            self:runCsbAction("idle", true)
            self.m_schDelay1 = true
        end)
        gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_show_choose_layer.mp3")
    end, 0.5)

    local labFreeSpin = self:findChild("free_spin_times")
    local labRespin = self:findChild("respin_times")
    
    --  z展示动画定义
    self.runCsbActionLock = "over1"
    self.runCsbActionfreespin = "over2"

end

function CrazyBombFeatureChooseView:onEnter()
    
    gLobalSoundManager:stopBgMusic()
    
end

function CrazyBombFeatureChooseView:onExit(  )

end

function CrazyBombFeatureChooseView:setChoseCallFun(choseFs, choseRespin)
    self.m_choseFsCallFun = choseFs
    self.m_choseRespinCallFun = choseRespin
end
function CrazyBombFeatureChooseView:clickFunc(sender)

    if self.m_isTouch == true or self.m_schDelay1 == false then
        return
    end
    self.m_isTouch = true
    gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_choose.mp3") 
    local name = sender:getName()
    local tag = sender:getTag()    
    self:clickButton_CallFun(name)
end
function CrazyBombFeatureChooseView:clickButton_CallFun(name)
    local tag=0
    if name == "btnRespin" then
        tag=1
    end
    self.m_featureChooseIdx = tag
    
    -- self.m_csbOwner["btnFreespin"]:setEnabled(false)
    -- self.m_csbOwner["btnRespin"]:setEnabled(false)
  
    for i = 1, 4, 1 do
        local particle = util_getChildByName(self, "Particle_"..i.."_"..tag)
        particle:setVisible(true)
        particle:resetSystem()
    end
    

    -- gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pig_break.mp3")

    self:choseOver( )

    -- scheduler.unschedulesByTargetName("LinkCat_CrazyBombFeatureChooseView")
end

function CrazyBombFeatureChooseView:bombMove(func )
    local endPos = cc.p(0,0)
    local startPos = cc.p(-display.width/2,-display.height/4)
    self:nodeJumpAction( startPos,endPos,1,func )

end

function CrazyBombFeatureChooseView:nodeJumpAction( startPos,endPos,flyTime,func )
    
    local node = cc.Node:create()
    local spinenode = util_spineCreateDifferentPath("CrazyBomb_Spine_chip", "CrazyBomb_Spine_chip", true, true)
    node:addChild(spinenode)
    self:findChild("root"):addChild(node,99999)
    node:setPosition(startPos)

    local actionList = {}

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        local scaleLIst = {}
        scaleLIst[#scaleLIst + 1] = cc.ScaleTo:create(flyTime,1)
        node:runAction(cc.Sequence:create(scaleLIst))
    end)
      
    actionList[#actionList + 1] = cc.EaseInOut:create(cc.JumpTo:create(flyTime, cc.p(endPos),200, 1),1)

    actionList[#actionList + 1] = cc.DelayTime:create(flyTime)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if node then
            node:removeFromParent()
        end
        func()
    end)
      
    node:runAction(cc.Sequence:create(actionList))

    self:runSpineAnim(spinenode,"idleframe",true)
end


function CrazyBombFeatureChooseView:runSpineAnim(spine,animName,loop,func)
    util_spinePlay(spine, animName, loop)
    if func ~= nil then
          util_spineEndCallFunc(spine, animName, func)
    end
end


function CrazyBombFeatureChooseView:choseOver( )
    self:initGameOver()
end

--进入游戏初始化游戏数据 判断新游戏还是断线重连 子类调用
function CrazyBombFeatureChooseView:initViewData(freeSpinNum, respinNum, func, changeBG)
    self.m_nFreeSpinNum = freeSpinNum
    self.m_csbOwner["free_spin_times"]:setString(freeSpinNum)
    self.m_csbOwner["respin_times"]:setString(respinNum)
    self.m_callFunc = func
    self.m_changeBG = changeBG
end

--初始化游戏结束状态 子类调用
function CrazyBombFeatureChooseView:initGameOver()
    
    if self.m_featureChooseIdx == 1 then
        self:runCsbAction(self.runCsbActionLock) 
    else
        self:runCsbAction(self.runCsbActionfreespin)
    end

    -- self:sendData(self.m_featureChooseIdx)
    if self.m_featureChooseIdx == 1 then
        -- gLobalSoundManager:playSound("LinkCatSounds/music_linkCat_choose_fs.mp3")
    else
        -- gLobalSoundManager:playSound("LinkCatSounds/music_linkCat_choose_reward.mp3") 
        if self.m_changeBG ~= nil then
            self.m_changeBG()
        end
    end

    local dropPig = util_spineCreateDifferentPath("CrazyBomb_Spine_Guochang", "CrazyBomb_Spine_Guochang", true, true)
    util_spinePlay(dropPig, "actionframe", false)
    gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_thief_run.mp3")
    self:findChild("root"):addChild(dropPig,100)
    util_spineEndCallFunc(dropPig, "actionframe", function()
        
        performWithDelay(self,function()      -- 下一帧 remove spine 不然会崩溃
            -- dropPig:removeFromParent()
            self:removeFromParent()
        end,0.0)
    end)

    util_spineFrameEvent(dropPig, "actionframe","show",function ()
        if self.m_callFunc then
            self.m_callFunc(self.m_featureChooseIdx)
        end
        self:setVisible(false)
    end)

    -- self:bombMove(function() 
    --     util_spinePlay(self.m_dropPig, "actionframe2", false)
    --     performWithDelay(self,function()
    --         if self.m_callFunc then
    --             self.m_callFunc(self.m_featureChooseIdx)
    --         end
    --         self:removeFromParent()
    --     end,0.5)
    -- end)
    
 
end

function CrazyBombFeatureChooseView:sendData(index)
    if self.m_isLocalData then
        -- scheduler.performWithDelayGlobal(function()
        --     self:recvBaseData(self:getLoaclData())
        -- end, 0.5,"BaseGameNew")
    else
        local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index}
        local httpSendMgr = SendDataManager:getInstance()
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    end
end

return CrazyBombFeatureChooseView