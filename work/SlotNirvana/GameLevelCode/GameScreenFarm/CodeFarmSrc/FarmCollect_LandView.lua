---
--xcyy
--2018年5月23日
--FarmCollect_LandView.lua

local FarmCollect_LandView = class("FarmCollect_LandView",util_require("base.BaseView"))

local STATES_LIST = {
    LOCK = 0,
    UNLOCK = 1,
    OVER = 2
}

local pageIndex = {
    niu = 4,
    zhu = 3,
    yang = 2,
    ji = 1

}

FarmCollect_LandView.m_clickStat = nil
FarmCollect_LandView.m_pos = nil
FarmCollect_LandView.m_NetPos = nil
FarmCollect_LandView.m_ClickFunc = nil
FarmCollect_LandView.m_pageIndex = nil
FarmCollect_LandView.m_CollectView = nil
FarmCollect_LandView.m_netIndex = nil


function FarmCollect_LandView:initUI()

    self:createCsbNode("Farm_game_yumidi.csb")

    self:addClick(self:findChild("click"))
    
    -- 初始不允许点击
    self.m_clickState = STATES_LIST.LOCK

end


function FarmCollect_LandView:onEnter()
 

end

function FarmCollect_LandView:setLandData( data)
    self.m_pos = data.pos
    self.m_pageIndex = data.pageIndex
    self.m_clickState = data.state
    self.m_NetPos = data.netPos
    self.m_score = data.score
    self.m_CollectView = data.view
    self.m_ClickFunc = data.func
    self.m_netIndex = data.netIndex

    self.m_buyType = data.buyType
    self.m_coins = data.coins

end

function FarmCollect_LandView:updateLandUI( )

    self:findChild("Node_coins_2"):setVisible(false)
    self:findChild("Node_Bonuswin"):setVisible(false)

    -- 只作为页面刚进入时或页面切换  初始化用
    if self.m_clickState == STATES_LIST.LOCK then
        

        if self.m_pageIndex and self.m_netIndex and self.m_pageIndex > self.m_netIndex then
            -- 大于服务器给的说明是 锁定的
            self:runCsbAction("idle1")
            
        else
            -- 小于等于的 说明钱不够
            self:runCsbAction("idle4")
            self:findChild("m_lb_coins_1"):setString(util_formatCoins(self.m_score,4,nil,nil,true))
            self:updateLabelSize({label=self:findChild("m_lb_coins_1"),sx=0.9,sy=0.9},106)
        end
        
        
    elseif self.m_clickState == STATES_LIST.OVER then

        
    

        if self.m_buyType then

            if self.m_buyType == "coins" then
                self:findChild("Node_coins_2"):setVisible(true)
                self:findChild("m_lb_coins_2"):setString(util_formatCoins(self.m_coins,3,nil,nil,true))
                self:updateLabelSize({label=self:findChild("m_lb_coins_2"),sx=1,sy=1},182)
            elseif self.m_buyType == "shopFreespin" then
                self:findChild("Node_coins_2"):setVisible(true)
                self:findChild("m_lb_coins_2"):setString(util_formatCoins(self.m_coins,3,nil,nil,true))
                self:updateLabelSize({label=self:findChild("m_lb_coins_2"),sx=1,sy=1},182)
            else
                self:findChild("Node_Bonuswin"):setVisible(true)
            end
            
        end
       
        self:runCsbAction("idle2")

        
    else
        self:runCsbAction("idle3")
        self:findChild("m_lb_coins_1"):setString(util_formatCoins(self.m_score,4,nil,nil,true))
        self:updateLabelSize({label=self:findChild("m_lb_coins_1"),sx=0.9,sy=0.9},106)

    end
end


function FarmCollect_LandView:onExit()
 
end

--默认按钮监听回调
function FarmCollect_LandView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_CollectView  then
        if self.m_CollectView:checkAllBtnClickStates( ) then
            -- 网络消息回来之前 所有按钮都不允许点击
            return
        end
    end
    

    if self.m_clickState ~= STATES_LIST.UNLOCK  then
        return
    end

    self.m_clickState = STATES_LIST.OVER

    if name == "click" then
       if self.m_ClickFunc then
            self.m_ClickFunc(self.m_NetPos,self.m_pos)
            self.m_ClickFunc = nil
       end 
        print("点击index"..self.m_pos.."页面"..self.m_pageIndex)
    end

end


return FarmCollect_LandView