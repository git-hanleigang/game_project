---
--smy
--2018年4月18日
--CandyBingoWheelView.lua


local CandyBingoWheelView = class("CandyBingoWheelView", util_require("base.BaseView"))
CandyBingoWheelView.m_randWheelIndex = nil
CandyBingoWheelView.m_wheelSumIndex = 9 -- 轮盘有多少块
CandyBingoWheelView.m_wheelData = {{num = 1,coins = 12},
    {num = 1,coins = 12},{num = 1,coins = 123},{num = 1,coins = 1234},
    {num = 2},{num = 5},{num = 4},{num = 3},{num = 3},
    {num = 1,coins = 12345678910},{num = 1,coins = 6},{num = 1,coins = 7}}-- 大轮盘信息

CandyBingoWheelView.m_wheelNode = {} -- 大轮盘Node 
CandyBingoWheelView.m_bIsTouch = nil

CandyBingoWheelView.m_Mini = 5
CandyBingoWheelView.m_Minor = 4
CandyBingoWheelView.m_Major = 3
CandyBingoWheelView.Grand = 2
CandyBingoWheelView.m_coins= 1

function CandyBingoWheelView:initUI(data)
    
    self:createCsbNode("CandyBingo/CandyBingo_Lunpan.csb") 

    self:changeBtnEnabled(false)

    self.m_bIsTouch = true
    self.m_wheel = require("CodeCandyBingoSrc.CandyBingoWheelAction"):create(self:findChild("lunpan"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()
    self.m_wheelData = self:getWheeldata(data.wheel)
    self.m_randWheelIndex = data.endIndex + 1

    self:createWheelnode( )

    

    self.CandyBingoWheelPoints = util_createView("CodeCandyBingoSrc.CandyBingoWheelPoints")
    self:findChild("points"):addChild(self.CandyBingoWheelPoints)


    self.CandyBingoPointsWinAction = util_createView("CodeCandyBingoSrc.CandyBingoPointsAction")
    self:findChild("pointsAction"):addChild(self.CandyBingoPointsWinAction)
    self.CandyBingoPointsWinAction:setVisible(false)

    
    self.CandyBingoWheelTipView = util_createView("CodeCandyBingoSrc.CandyBingoWheelTipView")
    self:findChild("tip"):addChild(self.CandyBingoWheelTipView)
    self.CandyBingoWheelTipView:setVisible(true)
    
    
    self.CandyBingoWheelPoints:runCsbAction("start")
    self.CandyBingoWheelPoints:setVisible(true)

    self:findChild("btnBegin"):setVisible(false)
    self:addClick(self:findChild("btnBegin"))

    

    

    util_setCascadeOpacityEnabledRescursion(self,true)


    

    -- -- gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_wheel_appear.mp3")
    

end

function CandyBingoWheelView:startAnimation()
    -- gLobalSoundManager:playSound("CandyBingoSounds/music_CandyBingo_wheel_appear.mp3")
    self:runCsbAction("start", false, function ()
        

        self.CandyBingoWheelPoints:setVisible(true)

        self:findChild("btnBegin"):setVisible(true)

    end)
end

function CandyBingoWheelView:initWheelBg( machine)
    self.m_machine = machine
end

function CandyBingoWheelView:getWheeldata( values)
    local list = {}
    for k,v in pairs(values) do
        local numinfo = {}
        if v == "Mini" then
            numinfo.num = 5
        elseif v == "Minor" then
            numinfo.num = 4
        elseif v == "Major" then
            numinfo.num = 3
        elseif v == "Grand" then
            numinfo.num = 2
        else
            numinfo.num = 1
            local lineBet = globalData.slotRunData:getCurTotalBet()
            numinfo.coins = tonumber(v) * lineBet
        end
        table.insert( list,  numinfo )
    end
    return list
end

function CandyBingoWheelView:createWheelnode( )
    self.m_wheelNode = nil
    self.m_wheelNode = {}

    for i=1,self.m_wheelSumIndex do
        local name =  "wheel_lab_score_".. self.m_wheelData[i].num ..".csb"
        local node =  util_createView("CodeCandyBingoSrc.CandyBingoWheelNode",name)
        self:findChild("shuzi_"..i):addChild(node)
        if self.m_wheelData[i].coins then
            local str = util_formatCoins(self.m_wheelData[i].coins,3)
            local coinsTab = self:ChangeStringToTable(str)

            node:setlabString(coinsTab)
        end
        node.index = self.m_wheelData[i]
        table.insert( self.m_wheelNode, node )
    end
    
end



--默认按钮监听回调
function CandyBingoWheelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btnBegin" then
        self:clickSelfFunc()
    end
end

function CandyBingoWheelView:clickSelfFunc()
    if self.m_bIsTouch == false then
        return
    end
    
    self:findChild("btnBegin"):setVisible(false)

    self:findChild("Button"):setEnabled(true)
    gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_click.mp3")
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    self.m_bIsTouch = false

    self:runCsbAction("idle")

    self.CandyBingoWheelTipView:setVisible(false)

    self.CandyBingoWheelPoints:runCsbAction("idle",true)

    self:beginWheelAction()

end


function CandyBingoWheelView:chooseRewordView( endindex ,callfunc)
    local view = nil
    local wincoins = 0
    local viewId = 1
    -- gLobalSoundManager:setBackgroundMusicVolume(0.4)
    local func = function(  )
        gLobalSoundManager:setBackgroundMusicVolume(1)
        callfunc()
    end

   
    
    if self.m_wheelData[endindex].num == self.m_Major then
        viewId = 2
        wincoins = self.m_machine:getJackPotCoins( )

    elseif self.m_wheelData[endindex].num == self.m_Mini then
        viewId = 4
        wincoins = self.m_machine:getJackPotCoins( )

    elseif self.m_wheelData[endindex].num == self.m_Minor then
        viewId = 3
        wincoins = self.m_machine:getJackPotCoins( )

    elseif self.m_wheelData[endindex].num == self.Grand then
        viewId = 1
        wincoins = self.m_machine:getJackPotCoins( )

    elseif  self.m_wheelData[endindex].num == self.m_coins then
        viewId = 5
        wincoins = self.m_wheelData[endindex].coins

    end

    view = util_createView("CodeCandyBingoSrc.CandyBingoJackPotWinView")
    view:initViewData(viewId,util_formatCoins(wincoins,11),self.m_machine,func)
    view.getRotateBackScaleFlag = function(  ) return false end
    -- view:setPosition(cc.p(-display.width/2,-display.height/2))--
    gLobalViewManager:showUI(view)
    
end

function CandyBingoWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        self.CandyBingoPointsWinAction:setVisible(true)

        self.CandyBingoWheelPoints:runCsbAction("idle")
        
        self:findChild("Button"):setEnabled(true)

        gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_show_wheel_Win_action.mp3")

        self.CandyBingoPointsWinAction:runCsbAction("animation0",true,function(  )
            -- self.CandyBingoPointsWinAction:setVisible(false)
            -- gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_wheel_stop.mp3")
           
        end)

        performWithDelay(self,function()
            self.CandyBingoPointsWinAction:setVisible(false)
            self.CandyBingoPointsWinAction:runCsbAction("animation0")

            gLobalSoundManager:playSound("CandyBingoSounds/music_CandyBingo_fs.mp3")

            self:chooseRewordView(self.m_randWheelIndex,function(  )
                callBackFun()
            end)
        end,2.3)
            
    end
end

function CandyBingoWheelView:onEnter()


end

function CandyBingoWheelView:onExit()
    
end

function CandyBingoWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("CandyBingo_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

function CandyBingoWheelView:beginWheelAction()

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
    self.m_wheel:recvData(self.m_randWheelIndex)

    
end

-- 返回上轮轮盘的停止位置
function CandyBingoWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

function CandyBingoWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function CandyBingoWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = (distance / targetStep) + 0.5
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
    --     -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_show_wheel_run.mp3")

   -- self:runCsbAction("animation0") 
    
    end
end


function CandyBingoWheelView:ChangeStringToTable(str )
    
    if str == nil or type(str) ~= "string" then
       return {}
    end

    local strArray = {}

    local strLen = string.len( str )
    local index = 0
    for i=1,strLen do
        local charStr =  string.sub(str,i,i)
        if charStr ~= "," then -- 不要逗号
            --if index <= 3 then
                table.insert( strArray, charStr )
            -- else
            --     if charStr == "K" or charStr == "M" or charStr == "B" then
            --         table.insert( strArray, charStr )
            --     end
            -- end
            index = index + 1
        end
        
    end

    return strArray
end




return CandyBingoWheelView