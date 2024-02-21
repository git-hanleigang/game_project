---
--island
--2018年4月12日
--WarriorAliceShowView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local PublicConfig = require "WarriorAlicePublicConfig"
local WarriorAliceShowView = class("WarriorAliceShowView", util_require("Levels.BaseLevelDialog"))


function WarriorAliceShowView:onEnter()
    WarriorAliceShowView.super.onEnter(self)

end
function WarriorAliceShowView:onExit()

    WarriorAliceShowView.super.onExit(self)
end

function WarriorAliceShowView:initUI(params)
    local path = params.path
    self:createCsbNode(path)
    self.btnName = params.btnName
    self.endFunc = params.endFunc
    self.isAuto = params.isAuto
    self.num = params.num
    self.guoChangFunc = params.guoChangFunc
    self.isRespin = params.isRespin or nil

    self:addChengBao()
    self.m_isClick = false
    self:showCurView()
end

function WarriorAliceShowView:addChengBao()
    self.chengBao = util_spineCreate("WarriorAlice_tb_chengbao", true, true)
    self:findChild("Node_chengbao"):addChild(self.chengBao)
end

function WarriorAliceShowView:showCurView()
    if self.num then
        self:findChild("m_lb_num"):setString(self.num)
    end
    
    if self.isAuto then
        -- self:findChild(self.btnName):setEnabled(false)
        util_spinePlay(self.chengBao, "auto", false)
        util_spineEndCallFunc( self.chengBao,"auto",function()
            self.chengBao:setVisible(false)
        end)
        self:runCsbAction("auto",false,function ()
            if self.endFunc then
                self.endFunc()
            end
            self:removeFromParent()
        end)
    else
        
        util_spinePlay(self.chengBao, "start", false)
        util_spineEndCallFunc( self.chengBao,"start",function()
            util_spinePlay(self.chengBao, "idle", false)
        end)
        self:runCsbAction("start",false,function ()
            self.m_isClick = true
            self:runCsbAction("idle",true)
        end)
    end
    
end

--点击回调
function WarriorAliceShowView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self.m_isClick then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_btn_click)
    if name == self.btnName then
        self.m_isClick = false
        if not self.isAuto then
            self:findChild(self.btnName):setEnabled(false)
            local actName = "over"
            if self.isRespin then
                actName = "over1"
            end
            util_spinePlay(self.chengBao, actName, false)
            util_spineEndCallFunc( self.chengBao,actName,function()
                self.chengBao:setVisible(false)
            end)
            if self.guoChangFunc then
                self.guoChangFunc()
            end
            self:runCsbAction("over", false)
            self:delayCallBack(2,function ()
                if self.endFunc then
                    self.endFunc()
                end
                self:removeFromParent()
            end)
        end
    end
    
end

--[[
    延迟回调
]]
function WarriorAliceShowView:delayCallBack(time, func)
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

return WarriorAliceShowView

