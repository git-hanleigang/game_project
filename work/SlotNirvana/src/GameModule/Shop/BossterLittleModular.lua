local BossterLittleModular=class("BossterLittleModular",util_require("base.BaseView"))

BossterLittleModular.viewIndex = nil

BossterLittleModular.showBtn = 1
BossterLittleModular.showtip = 2

BossterLittleModular.nowShowType = nil

function BossterLittleModular:initUI(csbpath,index)
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end

    self.callbackFunc = nil 
    self.viewIndex = index
    self:createCsbNode(csbpath,isAutoScale)


    self.m_TimeLeft_Action = util_createView("GameModule.Shop.ShopActionModular","Shop_Res/TimeLeft.csb")
    self:addChild(self.m_TimeLeft_Action)
    -- self.m_TimeLeft_Action:getLefttxt() -- Timeleftcont

    

    self.labLeftTime ,self.leftTimeImg = self.m_TimeLeft_Action:getLefttxt() -- 
    self.labLeftTime:setVisible(false)
    self.leftTimeImg:setVisible(false)
    self:updateChangeAction(self.showBtn,true)

    self.m_shop_freecoins_Action = util_createView("GameModule.Shop.ShopActionModular","Shop_Res/TxtFade.csb")
    self:addChild(self.m_shop_freecoins_Action)
    self.m_shop_freecoins_Action:setVisible(false)
    self.m_shop_freecoins_Action:setPosition(0,16.08)


    local trade_name = self:findChild("trade_name") 
    trade_name:setString("")

    if self.viewIndex == 1 then
        trade_name:setString("Cashback Deluxe")
    elseif self.viewIndex == 2 then
        trade_name:setString("Level Up Burst")
    elseif self.viewIndex == 3 then
        trade_name:setString("Bundle")
    end
    
    

    self:updateBtnPrice()
    -- self:runCsbAction("start")
    -- 是双buffbuff   
    if self.viewIndex == 3 then 
            -- 显示 first time specile 标识
        self:updatefirstTimeSpecileInfo()
    end
    if self.viewIndex == 3 then

        for i=1,3 do
            local WAS_lab_day_ = self:findChild("lab_day_"..i.."_0")
            
            WAS_lab_day_:setString("WAS "..SHOP_BUFF_BASE_DAY[self.viewIndex][i].." DAY")
        end
    end
    
    

        
end



function BossterLittleModular:updatefirstTimeSpecileInfo(  )
    local firstTimeSpecileTip =  self:findChild("title")
    firstTimeSpecileTip:setVisible(false)

    for i=1,3 do
        local node_fustbuy = self:findChild("node_fustbuy_"..i)
        local lab_day = self:findChild("lab_day_"..i)
        node_fustbuy:setVisible(false)
        lab_day:setPositionY(3)
    end
    
    if globalData.shopRunData.shopDoubleBurstEndTime == 0  then -- 没有购买过双重Buff then
        -- 显示 first time specile 标识
        firstTimeSpecileTip:setVisible(true)
        for i=1,3 do
            local node_fustbuy = self:findChild("node_fustbuy_"..i)
            local lab_day = self:findChild("lab_day_"..i)
            node_fustbuy:setVisible(true)
            lab_day:setPositionY(9)
        end

    end
end

function BossterLittleModular:updateBtnPrice(  )
    -- body
    for i=1,3 do
        -- 时间更新
        local btnday =  self:findChild("lab_day_"..i)
        local btndayNum = SHOP_BUFF_BASE_DAY[self.viewIndex][i] 

        -- 价格更新
        local btnPrice =  self:findChild("lab_money_"..i)
        local price = SHOP_BUFF_BASE_PRICE[self.viewIndex][i] / 100

        if globalData.shopRunData.shopDoubleBurstEndTime == 0 then -- 没有购买过双重Buff
            -- 是双buffbuff
            if self.viewIndex == 3 then
                price = SHOP_BUFF_BASE_PRICE[self.viewIndex + 1][i] / 100
                btndayNum = SHOP_BUFF_BASE_DAY[self.viewIndex+ 1][i] 
                
            end

        end

        btnday:setString("DAY "..btndayNum)  
        btnPrice:setString("$"..price)    
    end
    
end

function BossterLittleModular:onEnter()

end

function BossterLittleModular:onExit()
  
end

function BossterLittleModular:initViewData( func )
    -- body
    self.callbackFunc = func
end
function BossterLittleModular:updateChangeAction(type,action)
    
    local Btn_tip =  self:findChild("Btn_tip")
    Btn_tip:setTouchEnabled(false)

    for i=1,3 do
        local btn =  self:findChild("Button_"..i)
         btn:setVisible(true)
         btn:setTouchEnabled(false)
    end

    local btnback =  self:findChild("Btn_back")
    btnback:setVisible(true)
    btnback:setTouchEnabled(false)

    if type == self.showBtn then
        -- body
        if action then -- 初始化界面不播动画
            -- body
            btnback:setVisible(false)
            Btn_tip:setTouchEnabled(true)

            for i=1,3 do
                local btn =  self:findChild("Button_"..i)
                 btn:setVisible(true)
                 btn:setTouchEnabled(true)
            end

            return 
        end
        self:runCsbAction("animation1",false,function(  )
            -- body
            btnback:setVisible(false)
            Btn_tip:setTouchEnabled(true)

            for i=1,3 do
                local btn =  self:findChild("Button_"..i)
                 btn:setVisible(true)
                 btn:setTouchEnabled(true)
            end

        end)
    else

        self:runCsbAction("animation",false,function(  )
            -- body
            for i=1,3 do
                local btn =  self:findChild("Button_"..i)
                btn:setVisible(false)
            end

            
            local btnback =  self:findChild("Btn_back")
            btnback:setVisible(true)
            btnback:setTouchEnabled(true)
            Btn_tip:setTouchEnabled(true)
        end)
    end
end

function BossterLittleModular:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
  
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    print("BossterLittleModular ".. name.."  " ..self.viewIndex)

    if name=="Btn_tip" then
         print("Btn_tip")
         self:updateChangeAction(self.showtip)
     elseif name=="Button_1" then
        
        self:clickBuyBtn( self.viewIndex,1 )

         print("Button_1")
     elseif name=="Button_2" then 
        self:clickBuyBtn( self.viewIndex,2 )
         print("Button_2")

    elseif name=="Button_3" then 
        self:clickBuyBtn( self.viewIndex,3 )
        print("Button_3")
     elseif name=="Btn_back"then 
        print("Btn_back")
        self:updateChangeAction(self.showBtn)
     end

end

function BossterLittleModular:updataLeftTimImg( isShow,isAction )
    -- body

    self.labLeftTime:setVisible(isShow)
    self.leftTimeImg:setVisible(isShow)
    
end

function BossterLittleModular:clickBuyBtn( buytype,index )
    -- body
    if self.callbackFunc then
        -- body
        self.callbackFunc(buytype,index)
    end
    
end
function BossterLittleModular:updateLeftTime( endTime )
    -- body
    local time = os.time()
    -- endTime = 1544186460
    local leftTime = endTime - time

    if leftTime <= 0 then
        -- body
        leftTime = 0
        self:updataLeftTimImg(false,true)
        if self.m_shop_freecoins_Action:isVisible() then
            self.m_shop_freecoins_Action:setVisible(false)
            self.m_shop_freecoins_Action:runCsbAction("show",false,function(  )
                -- body
            end)
        end
        -- if not self.m_shop_freecoins_Action:isVisible()  then

        --     self.m_shop_freecoins_Action:setVisible(true)
        --     self.m_shop_freecoins_Action:runCsbAction("show",true)
        -- end
        self.labLeftTime:setScale(0.45)
        self.leftTimeImg:setScale(0.45)
    else
        self:updataLeftTimImg(true,true)

        if not self.m_shop_freecoins_Action:isVisible() and leftTime < 5 then

            self.m_shop_freecoins_Action:setVisible(true)
            self.m_shop_freecoins_Action:runCsbAction("show",true)
            
            
        end
        if leftTime == 1 then
            self.m_shop_freecoins_Action:setVisible(false)
            self.m_shop_freecoins_Action:runCsbAction("show",false)

            self.m_TimeLeft_Action:runCsbAction("Timeleftcont",false,function(  )
                
            end)
        end

    end

    local isday,str = self:getDayOrTimeState(leftTime)

    self.labLeftTime:setString(str)
end


function BossterLittleModular:getDayOrTimeState( Ostime)
    local isDay = false
    local timeStr = ""


    if Ostime > ONE_DAY_TIME_STAMP then

        timeStr = math.modf( Ostime / ONE_DAY_TIME_STAMP ) .." DAYS"
        isDay =  true
    else
        isDay =  false
        timeStr = util_count_down_str(Ostime)
    end


    return isDay,timeStr
end


return BossterLittleModular