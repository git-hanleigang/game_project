---
--smy
--2018年4月18日
--CrazyBombWheelView.lua


local CrazyBombWheelView = class("CrazyBombWheelView", util_require("base.BaseView"))
CrazyBombWheelView.m_randWheelIndex = nil
CrazyBombWheelView.m_wheelSumIndex = 24 -- 轮盘有多少块
CrazyBombWheelView.m_wheelData = {{num = 1},{num = 1},{num = 1},{num = 3},{num = 1},{num = 1},{num = 1},{num = 1},{num = 1},{num = 1},{num = 1}
,{num = 1},{num = 1},{num = 4},{num = 1},{num = 1},{num = 1},{num = 1},{num = 1},{num = 1},{num = 1},{num = 1},{num = 1},{num = 1}} -- 大轮盘信息
CrazyBombWheelView.m_wheelNode = {} -- 大轮盘Node 
CrazyBombWheelView.m_bIsTouch = nil

CrazyBombWheelView.m_Feature = 7
CrazyBombWheelView.m_FreeGame = 6
CrazyBombWheelView.m_Mini = 5
CrazyBombWheelView.m_Minor = 4
CrazyBombWheelView.m_Major = 3
CrazyBombWheelView.Grand = 2
CrazyBombWheelView.m_coins= 1

function CrazyBombWheelView:initUI(data)
    
    self:createCsbNode("CrazyBomb_Wheel.csb") 

    self:changeBtnEnabled(false)

    self.m_wheelSumIndex = #data.values
    self.m_bIsTouch = true
    self.m_wheel = require("CodeCrazyBombSrc.CrazyBombWheelAction"):create(self:findChild("runWheel"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()
    self.m_wheelData = self:getWheeldata(data.values)
    self.m_randWheelIndex =  data.value + 1

    self:createWheelnode( )

    self.m_clickAnimation = util_createView("CodeCrazyBombSrc.CrazyBombWheelClickAnimation") 
    self:findChild("Node_flsh_clish"):addChild(self.m_clickAnimation)
    self.m_clickAnimation:setVisible(false)

    
    self.m_RewordGift = util_createView("CodeCrazyBombSrc.CrazyBombWheelRewordGift") 
    self:findChild("Node_flsh"):addChild(self.m_RewordGift)
    self.m_RewordGift:setVisible(false)
    
    self.m_WheelPoint= util_createView("CodeCrazyBombSrc.CrazyBombWheelPoint") 
    self:findChild("Node_Point"):addChild(self.m_WheelPoint)
    self.m_WheelPoint:setVisible(false)
    self:findChild("CrazyBomb_wheel_zhizhen_2"):setVisible(true)
    

    -- gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_wheel_appear.mp3")
    

end

function CrazyBombWheelView:startAnimation()
    gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_wheel_appear.mp3")
    self:runCsbAction("start", false, function ()
        self:runCsbAction("tishi", true)

        self.m_WheelPoint:setVisible(true)
        self:findChild("CrazyBomb_wheel_zhizhen_2"):setVisible(false)

        self:setTouchLayer()
    end)
end

function CrazyBombWheelView:initWheelBg( father,machine)
    self.m_Wheelbg = father
    self.m_machine = machine
end

function CrazyBombWheelView:getWheeldata( values)
    local list = {}
    for k,v in pairs(values) do
        local numinfo = {}
        if v == "Feature" then
            numinfo.num = 7
            
        elseif v == "FreeGame" or v == "Free Game" then
            numinfo.num = 6
        elseif v == "Mini" then
            numinfo.num = 5
        elseif v == "Minor" then
            numinfo.num = 4
        elseif v == "Major" then
            numinfo.num = 3
        elseif v == "Grand" then
            numinfo.num = 2
        else
            numinfo.num = 1
            numinfo.coins = tonumber(v)
        end
        table.insert( list,  numinfo )
    end
    return list
end

function CrazyBombWheelView:createWheelnode( )
    self.m_wheelNode = nil
    self.m_wheelNode = {}

    for i=1,self.m_wheelSumIndex do
        local name =  "CrazyBomb_Wheel_lab".. self.m_wheelData[i].num ..".csb"
        local node =  util_createView("CodeCrazyBombSrc.CrazyBombWheelNode",name)
        self:findChild("reward_"..i):addChild(node)
        if self.m_wheelData[i].coins then
            
            node:setlabString(util_formatCoins(self.m_wheelData[i].coins,4))
        end
        node.index = self.m_wheelData[i]
        table.insert( self.m_wheelNode, node )
    end
    
end

function CrazyBombWheelView:setTouchLayer()
    local function onTouchBegan_callback(touch, event)
        return true
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        self:clickFunc()
    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved_callback,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded_callback,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()    
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function CrazyBombWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end
    gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_click_wheel.mp3")
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    self.m_bIsTouch = false

    self:runCsbAction("idle")
    self.m_clickAnimation:setVisible(true)
    self.m_clickAnimation:runCsbAction("animation0",false,function(  )
        self.m_clickAnimation:setVisible(false)
    end)

    self:beginWheelAction()

end


function CrazyBombWheelView:chooseRewordView( endindex ,callfunc)
    local view = nil
    local wincoins = 0
    gLobalSoundManager:setBackgroundMusicVolume(0.4)
    local func = function(  )
        gLobalSoundManager:setBackgroundMusicVolume(1)
        callfunc()
    end
    gLobalSoundManager:setBackgroundMusicVolume(0.4)
    if self.m_wheelData[endindex].num == self.m_Feature then
        view = util_createView("CodeCrazyBombSrc.CrazyBombWheelFeatherWinView",0)
        view:initViewData(func)
        gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pop_win_2.mp3")
    elseif self.m_wheelData[endindex].num == self.m_FreeGame then
        view = util_createView("CodeCrazyBombSrc.CrazyBombWheelFeatherWinView",1)
        view:initViewData(func)
        gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pop_win_2.mp3")      
    elseif self.m_wheelData[endindex].num == self.m_Major then
        view = util_createView("CodeCrazyBombSrc.CrazyBombWheelJackPotWinView")
        view:initViewData(2,self.m_machine:getJackPotCoins( ),func)
        wincoins = self.m_machine:getJackPotCoins( )
        gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pop_win_2.mp3")
    elseif self.m_wheelData[endindex].num == self.m_Mini then
        view = util_createView("CodeCrazyBombSrc.CrazyBombWheelJackPotWinView")
        view:initViewData(4,self.m_machine:getJackPotCoins( ),func)
        wincoins = self.m_machine:getJackPotCoins( )
        gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pop_win_2.mp3")
    elseif self.m_wheelData[endindex].num == self.m_Minor then
        view = util_createView("CodeCrazyBombSrc.CrazyBombWheelJackPotWinView")
        view:initViewData(3,self.m_machine:getJackPotCoins( ),func)
        wincoins = self.m_machine:getJackPotCoins( )
        gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pop_win_2.mp3")
    elseif self.m_wheelData[endindex].num == self.Grand then
        view = util_createView("CodeCrazyBombSrc.CrazyBombWheelJackPotWinView")
        view:initViewData(1,self.m_machine:getJackPotCoins( ),func)
        wincoins = self.m_machine:getJackPotCoins( )
        gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pop_win_2.mp3")
    elseif  self.m_wheelData[endindex].num == self.m_coins then
        view = util_createView("CodeCrazyBombSrc.CrazyBombWheelCoinsWinView")
        view:initViewData(self.m_wheelData[endindex].coins,func)
        wincoins = self.m_wheelData[endindex].coins
        gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pop_win_1.mp3")
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{wincoins, GameEffect.EFFECT_BONUS})
    -- view:setPosition(cc.p(-display.width/2,-display.height/2))
    self.m_Wheelbg:findChild("rewordView"):addChild(view,9999)
end

function CrazyBombWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()

            self.m_RewordGift:setVisible(true)
            self.m_RewordGift:runCsbAction("actionframe",true)
            gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_wheel_stop.mp3")
            performWithDelay(self,function()
                self:chooseRewordView(self.m_randWheelIndex,function(  )
                    callBackFun()
                end)
            end,2)
    end
end

function CrazyBombWheelView:onEnter()

end

function CrazyBombWheelView:onExit()
    
end

function CrazyBombWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("CrazyBomb_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

function CrazyBombWheelView:beginWheelAction()

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
    self.m_wheel:beginWheel(true)
    self.m_wheel:recvData(self.m_randWheelIndex)

    
end

-- 返回上轮轮盘的停止位置
function CrazyBombWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

function CrazyBombWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function CrazyBombWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = (distance / targetStep) + 0.5
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
    --     -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 

    --     self.m_WheelPoint:runCsbAction("animation0") 
        
    --     -- self:runCsbAction("animation0") 
        gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_wheel_rptate.mp3")       
    end
end





return CrazyBombWheelView