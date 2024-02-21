---
--smy
--2018年4月18日
--CoinCircusWheelView.lua

local Config              = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")
local CoinCircusWheelView = class("CoinCircusWheelView", util_require("Levels.BaseLevelDialog"))
CoinCircusWheelView.m_randWheelIndex = nil
CoinCircusWheelView.m_wheelSumIndex =  4 -- 轮盘有多少块

function CoinCircusWheelView:initUI(_data)
    --[[
        _data = {
            machine = machine
        }
    ]]
    self.m_machine = _data.machine
    self:createCsbNode("CoinCircus_jackpot_zhuanpan.csb") 


    self.m_man_1 = util_spineCreate(Config.UISpinePath.WheelMain1,true,true)
    self:findChild("xiaochou_1"):addChild(self.m_man_1)
    self.m_man_1:setVisible(false)

    self.m_man_2 = util_spineCreate(Config.UISpinePath.WheelMain2,true,true)
    self:findChild("xiaochou_2"):addChild(self.m_man_2)
    self.m_man_2:setVisible(false)

    self.m_dark = util_createAnimation(Config.UICsbPath.WheelDark )
    self:addChild(self.m_dark,-1)
    self.m_dark:setVisible(false)

    self.m_jpBar = util_createView(Config.ViewPathConfig.WheelJpBar)
    self:findChild("Node_JpBar"):addChild(self.m_jpBar)

    self.m_playWheelEnd = false

    self:findChild("Button_1"):setVisible(false)

    self.m_wheel = require(Config.ViewPathConfig.WheelAction):create(self:findChild("wheel"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()
    self:setWheelRotEndModel( )

end

-- 转盘转动结束调用
function CoinCircusWheelView:initCallBack(_endIndex,_callBackFun,_jpindex,_winCoins)

    self.m_randWheelIndex = _endIndex  -- 设置轮盘滚动位置
    local jpindex = _jpindex 
    local winCoins = _winCoins

    self.m_callFunc = function()

        gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_WheelEnd_Win_ManSound.mp3")
        gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_WheelEnd_Win.mp3")

        self:runCsbAction("actionframe",false,function(  )

            self:playJpRewordViewShowAni(jpindex )

            self:runCsbAction("over")

            self:showJackpotView(jpindex,winCoins,function(  )
                _callBackFun()
            end)

        end)

        
    end
end


function CoinCircusWheelView:onExit()
    
    gLobalNoticManager:removeAllObservers(self)
end

function CoinCircusWheelView:clickFunc(sender)


    local btnName = sender:getName()
    
    gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_Click.mp3")  

    if btnName == "Button_1" then

        self:runCsbAction("idle2",true)

        sender:setEnabled(false)

        self:playClickWheelAni(  )

        self:beginWheelAction()

    end

end


-- 设置转盘盘滚动参数
function CoinCircusWheelView:beginWheelAction()

    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 150 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 110 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_callFunc

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()
    -- 设置轮盘功能滚动结束停止位置
    self.m_wheel:recvData(self.m_randWheelIndex)

    
end


-- 设置轮盘实时滚动调用
function CoinCircusWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function CoinCircusWheelView:setRotionAction( distance,targetStep,isBack )
  
    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then

        self.distance_pre = self.distance_now 
        gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_wheel_rptate.mp3")       
    end
end

-- 设置轮盘实时滚动调用
function CoinCircusWheelView:setWheelRotEndModel( )
   
    self.m_wheel:setWheelRotEndFunc( function()
        self:setRotionEndAction()
    end)
end


function CoinCircusWheelView:setRotionEndAction( )
    if not self.m_playWheelEnd then
        self.m_playWheelEnd = true
        self:playRewordWheelAni(  )
    end
end


function CoinCircusWheelView:playShowWheelAni(_func )
    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    self.m_dark:setVisible(true)
    self.m_dark:runCsbAction("start")
    self:runCsbAction("start")
    self.m_man_1:setVisible(true)
    util_spinePlay(self.m_man_1,"actionframe")

    performWithDelay(waitNode,function(  )

        util_spinePlay(self.m_man_1,"actionframe2")
        performWithDelay(waitNode,function(  )
            self:runCsbAction("idle1",true) 
            util_spinePlay(self.m_man_1,"idleframe",true)
            self:findChild("Button_1"):setVisible(true)

            if _func then
                _func()
            end
            waitNode:removeFromParent()
        end,35/30)
    end,60/30)
    


end

function CoinCircusWheelView:playClickWheelAni( _func )

    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    self.m_man_1:setVisible(true)
    util_spinePlay(self.m_man_1,"actionframe3")

    performWithDelay(waitNode,function(  )

        util_spinePlay(self.m_man_1,"idleframe2",true)
        self:findChild("Button_1"):setVisible(true)

        if _func then
            _func()
        end
        waitNode:removeFromParent()

    end,20/30)
    
end

function CoinCircusWheelView:playRewordWheelAni(  )

    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(waitNode,function(  )

        self.m_man_1:setVisible(true)
        util_spinePlay(self.m_man_1,"actionframe4")

        waitNode:removeFromParent()
    end,1.7)
    
end

function CoinCircusWheelView:playJpRewordViewShowAni(_jpIndex, _func )

    local aniName = {"8","5","7","6"}
    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    self.m_man_1:setVisible(true)
    util_spinePlay(self.m_man_1,"actionframe"..aniName[_jpIndex])

    self.m_man_2:setVisible(true)
    util_spinePlay(self.m_man_2,"actionframe"..aniName[_jpIndex])

    performWithDelay(waitNode,function(  )

        if _func then
            _func()
        end
        waitNode:removeFromParent()

    end,60/30)
    
end

function CoinCircusWheelView:showJackpotView(index,coins,func)

    -- gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_jackpot_window.mp3")
    local jackPotWinView = util_createView("CoinCircusSrc.CoinCircusJackPotWinView", self.m_machine)
    self:findChild("Node_JpReword"):addChild(jackPotWinView)
    

    jackPotWinView:initViewData(index,coins,function()

        util_spinePlay(self.m_man_1,"over")
        local waitNode=cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )

            self.m_man_1:setVisible(false)

            self.m_dark:runCsbAction("over",false,function(  )
                self.m_dark:setVisible(false)
            end)
    
            jackPotWinView:runCsbAction("over",false,function(  )
    
                jackPotWinView:removeFromParent()
    
                if func ~= nil then 
                    func()
                end 
            end)
            
            waitNode:removeFromParent()
            
        end,18/30)
        
        
    end)
end

return CoinCircusWheelView