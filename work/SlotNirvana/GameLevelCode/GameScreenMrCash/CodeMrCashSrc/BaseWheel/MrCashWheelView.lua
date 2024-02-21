---
--smy
--2018年4月18日
--MrCashWheelView.lua


local MrCashWheelView = class("MrCashWheelView", util_require("base.BaseView"))
MrCashWheelView.m_randWheelIndex = nil
MrCashWheelView.m_wheelSumIndex =  8 -- 轮盘有多少块
MrCashWheelView.m_wheelData = {} -- 大轮盘信息
MrCashWheelView.m_wheelNode = {} -- 大轮盘Node 
MrCashWheelView.m_bIsTouch = nil

function MrCashWheelView:initUI(data)
    
    self:createCsbNode("MrCash_Wheel.csb") 

    self:changeBtnEnabled(false)


    self.m_TipPoint = util_spineCreate("MrCash_shouzhi",true,true)
    self:findChild("TipPoint"):addChild(self.m_TipPoint)
    util_spinePlay(self.m_TipPoint,"idleframe",true) 
    self.m_TipPoint:setPositionY(-8)
    self.m_TipPoint:setPositionX(1)


    self.m_bIsTouch = true
    self.m_wheel = require("CodeMrCashSrc.BaseWheel.MrCashWheelAction"):create(self:findChild("zhuanpan"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    self:setWheelData(data.wheel ) -- 设置轮盘信息
    self.m_randWheelIndex = data.select -- 设置轮盘滚动位置
    self.m_parent = data.parent

    self:getWheelSymbol()

    self:addClick(self:findChild("click"))

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)

end

function MrCashWheelView:WheelSpinFunc( )

    self.m_TipPoint:setVisible(false)

    gLobalSoundManager:playSound("MrCashSounds/music_MrCash_BrnClick.mp3")

    self:runCsbAction("clicked")
    self.m_parent:CashManRotatingDisc( function(  )
        self:beginWheelAction()
    end )
end

--默认按钮监听回调
function MrCashWheelView:clickFunc(sender)
    
    if self.m_bIsTouch == false then
        return
    end

    self.m_bIsTouch = false

    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        
        self.m_actNode:stopAllActions()

        self:WheelSpinFunc( )
        
    end
    
end



-- 转盘转动结束调用
function MrCashWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()

        if callBackFun then
            callBackFun()
        end

          
    end
end

function MrCashWheelView:onEnter()

end

function MrCashWheelView:onExit()
    
end

function MrCashWheelView:changeBtnEnabled( isCanTouch)
    self:findChild("click"):setVisible(isCanTouch)
end

-- 设置转盘盘滚动参数
function MrCashWheelView:beginWheelAction()

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

-- 返回上轮轮盘的停止位置
function MrCashWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

-- 设置轮盘实时滚动调用
function MrCashWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function MrCashWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        -- self:runCsbAction("animation0") 
        gLobalSoundManager:playSound("MrCashSounds/sound_MrCash_wheel_rptate.mp3")       
    end
end

-- 设置轮盘网络消息
function MrCashWheelView:setWheelData(data )
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

function MrCashWheelView:getWheelSymbol(  )
    self.m_bigWheelNode = {}

    -- 第一个是jackpot

    for i = 1, self.m_wheelSumIndex - 1 , 1 do

        local WheelData = self.m_bigWheelData[i + 1]
        if WheelData == "jackpot" then
            print("jackpot不创建")
        else

            local labNode = util_createAnimation("MrCash_Wheel_zi.csb")
            self:findChild("text_"..i):addChild(labNode)
            local coinsNum = tonumber(self.m_bigWheelData[i + 1]) 
            local txt = labNode:findChild("BitmapFontLabel_1")
            if txt then
                txt:setString(util_formatCoins(coinsNum, 3))
            end
            
            self.m_bigWheelNode[#self.m_bigWheelNode + 1] = labNode

        end
        
    end
    
end

return MrCashWheelView