---
--xcyy
--2018年5月23日
--CoinManiaJpGameLoadingBarView.lua

local CoinManiaJpGameLoadingBarView = class("CoinManiaJpGameLoadingBarView",util_require("base.BaseView"))


function CoinManiaJpGameLoadingBarView:initUI(machine)

    self:createCsbNode("CoinMania_JackPot_wanfa_jindutiao.csb")

    self.m_machine = machine
    
    self:initLoadingTip( )

    self:runCsbAction("idleframe",true)

    
    self.m_baozhu = util_createAnimation("CoinMania_jackpot_baozhu.csb")
    self.m_machine.m_JackPotBar:findChild("Node_baozhu"):addChild(self.m_baozhu,10)

end


function CoinManiaJpGameLoadingBarView:onEnter()
 

end

function CoinManiaJpGameLoadingBarView:showAdd()
    
end
function CoinManiaJpGameLoadingBarView:onExit()
 
end

--默认按钮监听回调
function CoinManiaJpGameLoadingBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

function CoinManiaJpGameLoadingBarView:initLoadingTip( )

    for index = 1 , 6 do
        local addName =  "Node_bar_" .. index
        self[ "bar" .. index] = util_createAnimation("CoinMania_JackPot_wanfa_jindutiao_0.csb")
        self:findChild(addName):addChild( self[ "bar" .. index] )
        self[ "bar" .. index]:runCsbAction("idleframe")    
    end

end

function CoinManiaJpGameLoadingBarView:runBaoZhuZha( actType )
    local actid = actType
    self.m_baozhu:runCsbAction("actionframe"..actid,false,function(  )
        if actid == 1 then
            self.m_baozhu:runCsbAction("idle2",true)
        else 
            self.m_baozhu:runCsbAction("idle3",true) 
        end
    end)
end

function CoinManiaJpGameLoadingBarView:updateLoadingTipActStates( )

    local coinGroupNum = 0
    for index = 1 , 6 do

        if self[ "bar" .. index] then
            if index <= self.m_machine.m_pigNum then
                coinGroupNum = coinGroupNum + 1
                self[ "bar" .. index].m_isAdd = true
                self[ "bar" .. index]:runCsbAction("idleframe1")
            else
                self[ "bar" .. index].m_isAdd = nil
                self[ "bar" .. index]:runCsbAction("idleframe")
            end
        end
        
    end
    
    self.m_baozhu:runCsbAction("idle1",true)
    if coinGroupNum >= 1 and coinGroupNum < 3 then
        self.m_baozhu:runCsbAction("idle2",true)
    elseif coinGroupNum >= 3  then   
        self.m_baozhu:runCsbAction("idle3",true) 
    end
end

function CoinManiaJpGameLoadingBarView:getActBarNode( )
    
    for index = 1 , 6 do
        
        if self[ "bar" .. index] and not self[ "bar" .. index].m_isAdd then
            return  self[ "bar" .. index] , index
        end
        
    end

end

return CoinManiaJpGameLoadingBarView