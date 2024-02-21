---
--smy
--2018年5月24日
--LightCherryFeatureChooseView.lua
local SendDataManager = require "network.SendDataManager"
local PublicConfig = require "LightCherryPublicConfig"
local LightCherryFeatureChooseView = class("LightCherryFeatureChooseView", util_require("base.BaseView"))
LightCherryFeatureChooseView.m_choseFsCallFun = nil
LightCherryFeatureChooseView.m_choseRespinCallFun = nil

local BTN_TAG_FREE          =           1001
local BTN_TAG_RESPIN        =           1002

function LightCherryFeatureChooseView:initUI(params)
    self.m_machine = params.machine
    self:initViewData(params.freeCount,params.func)
    --背景动效
    self.m_spine_bgAni = util_spineCreate("GameScreenLightCherryChoose",true,true)
    self:addChild(self.m_spine_bgAni)
    self.m_spine_bgAni:setVisible(false)

    self.m_spine_ani = util_spineCreate("GameScreenLightCherryChoose",true,true)
    self:addChild(self.m_spine_ani)

    local lbl_freeCount = util_createAnimation("LightCherry_free_count.csb")
    util_spinePushBindNode(self.m_spine_ani,"shuzi2",lbl_freeCount)
    self.m_spine_ani.m_lbl_freeCount = lbl_freeCount
    lbl_freeCount:findChild("m_lb_num"):setString(self.m_nFreeSpinNum)
    util_setCascadeOpacityEnabledRescursion(lbl_freeCount,true)

    --创建点击区域
    local click_free = ccui.Layout:create() 
    self:addChild(click_free)    
    click_free:setAnchorPoint(1,0.5)
    click_free:setContentSize(CCSizeMake(display.width * 0.35,display.height * 0.65))
    click_free:setTouchEnabled(true)
    self:addClick(click_free)
    click_free:setTag(BTN_TAG_FREE)

    local click_respin = ccui.Layout:create() 
    self:addChild(click_respin)    
    click_respin:setAnchorPoint(0,0.5)
    click_respin:setContentSize(CCSizeMake(display.width * 0.35,display.height * 0.65))
    click_respin:setTouchEnabled(true)
    self:addClick(click_respin)
    click_respin:setTag(BTN_TAG_RESPIN)

    --显示区域
    -- click_free:setBackGroundColor(cc.c3b(255, 0, 0))
    -- click_free:setBackGroundColorOpacity(255)
    -- click_free:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)

    -- click_respin:setBackGroundColor(cc.c3b(0, 255, 0))
    -- click_respin:setBackGroundColorOpacity(255)
    -- click_respin:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)


    self.m_isWaitting = true
end

function LightCherryFeatureChooseView:onEnter()
    LightCherryFeatureChooseView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:featureResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
    
    self:showAni()
end

function LightCherryFeatureChooseView:onExit(  )
    LightCherryFeatureChooseView.super.onExit(self)

end

function LightCherryFeatureChooseView:showAni()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_LightCherry_show_choose_start) 

    util_spinePlay(self.m_spine_ani,"start")
    -- util_spineEndCallFunc(self.m_spine_ani,"start",function()
    --     self.m_isWaitting = false
    --     self.m_spine_bgAni:setVisible(true)
    --     util_spinePlay(self.m_spine_bgAni,"idle1",true)
    --     util_spinePlay(self.m_spine_ani,"idle2",true)
    -- end)
    self:delayCallBack(25/30,function ()
        self.m_isWaitting = false
        self.m_spine_bgAni:setVisible(true)
        util_spinePlay(self.m_spine_bgAni,"idle1",true)
        util_spinePlay(self.m_spine_ani,"idle2",true)
    end)
end

function LightCherryFeatureChooseView:setChoseCallFun(choseFs, choseRespin)
    self.m_choseFsCallFun = choseFs
    self.m_choseRespinCallFun = choseRespin
end

--[[
    点击回调
]]
function LightCherryFeatureChooseView:clickFunc(sender)
    if self.m_isWaitting then
        return
    end
    self.m_isWaitting = true
    local name = sender:getName()
    local tag = sender:getTag()   

    if tag == BTN_TAG_FREE then
        self.m_featureChooseIdx = 0
    elseif tag == BTN_TAG_RESPIN then
        self.m_featureChooseIdx = 1
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_LightCherry_click_choose)
    self:sendData(self.m_featureChooseIdx)
end

--[[
    发送数据
]]
function LightCherryFeatureChooseView:sendData(index)
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_machine.m_isShowTournament)
end

--[[
    网络消息返回
]]
function LightCherryFeatureChooseView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "FEATURE" then
            
            self:runOverAni()
        end
    end
end

function LightCherryFeatureChooseView:runOverAni( )
    local endFunc = function()
        if type(self.m_callFunc) == "function" then
            self.m_callFunc(self.m_featureChooseIdx)
        end
    end

    local params = {}
    if self.m_featureChooseIdx == 1 then
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_ani,   --执行动画节点  必传参数
            actionName = "fankui2", --动作名称  动画必传参数,单延时动作可不传
        }
        
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_ani,   --执行动画节点  必传参数
            actionName = "fankui4", --动作名称  动画必传参数,单延时动作可不传
            soundFile = PublicConfig.SoundConfig.sound_LightCherry_click_choose_move,  --播放音效 执行动作同时播放 可选参数
        }
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_ani,   --执行动画节点  必传参数
            actionName = "idle4", --动作名称  动画必传参数,单延时动作可不传
            callBack = function()
                self.m_spine_bgAni:setVisible(false)
            end,   --回调函数 可选参数
        }
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_ani,   --执行动画节点  必传参数
            actionName = "over2", --动作名称  动画必传参数,单延时动作可不传
            soundFile = PublicConfig.SoundConfig.sound_LightCherry_hide_choose_start,  --播放音效 执行动作同时播放 可选参数
            callBack = function()
                endFunc()
                performWithDelay(self,function()
                    self:removeFromParent()
                end,0.1)
            end,   --回调函数 可选参数
        }
    else
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_ani,   --执行动画节点  必传参数
            actionName = "fankui1", --动作名称  动画必传参数,单延时动作可不传
        }
        
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_ani,   --执行动画节点  必传参数
            actionName = "fankui3", --动作名称  动画必传参数,单延时动作可不传
            soundFile = PublicConfig.SoundConfig.sound_LightCherry_click_choose_move,  --播放音效 执行动作同时播放 可选参数
            
        }
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_ani,   --执行动画节点  必传参数
            actionName = "idle3", --动作名称  动画必传参数,单延时动作可不传
            callBack = function()
                self.m_spine_bgAni:setVisible(false)
            end,   --回调函数 可选参数
        }
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_ani,   --执行动画节点  必传参数
            actionName = "over1", --动作名称  动画必传参数,单延时动作可不传
            soundFile = PublicConfig.SoundConfig.sound_LightCherry_hide_choose_start,  --播放音效 执行动作同时播放 可选参数
            callBack = function()
                endFunc()
                performWithDelay(self,function()
                    self:removeFromParent()
                end,0.1)
            end,   --回调函数 可选参数
        }
    end 
    util_runAnimations(params)
end

function LightCherryFeatureChooseView:initViewData(freeSpinNum,func)
    self.m_nFreeSpinNum = freeSpinNum
    self.m_callFunc = func
end

--延迟回调
function LightCherryFeatureChooseView:delayCallBack(time, func)
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

return LightCherryFeatureChooseView