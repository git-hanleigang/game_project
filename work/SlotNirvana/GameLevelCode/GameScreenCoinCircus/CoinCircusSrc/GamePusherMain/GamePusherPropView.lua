local GamePusherPropView = class("GamePusherPropView", util_require("base.BaseView"))
local Config              = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")
local GamePusherManager   = require "CoinCircusSrc.GamePusherManager"

local VEC_POS_NAME = 
{
    "dangban",
    "shake",
    "bigcoin",
    "jackpot"
}

local VEC_BTN_NAME = 
{
    "btn_wall",
    "btn_shake",
    "btn_bigCoins"
}

local VEC_PROP_TYPE =
{
    shakeMaxUseNum = 0,
    wallMaxUseNum = 1,
    bigCoinMaxUseNum = 2
}

local VEC_PROP_TIP =
{
    btn_wall = "wall_free",
    btn_shake = "shake_free",
    btn_bigCoins = "huge_free"
}

function GamePusherPropView:ctor( )

    self.m_pGamePusherMgr  =  GamePusherManager:getInstance()

    GamePusherPropView.super.ctor(self )
    
end

function GamePusherPropView:initUI(path)
    
    self:createCsbNode("CoinCircus_daoju_shouji.csb", false)
    self:setTouchEnabled( true )

    local slotMainScale = self.m_pGamePusherMgr:getSlotMainRootScale()
    self:findChild("Node_scale"):setScale(slotMainScale)

    self.m_SpecClickEnable  = false -- 特殊条件点击判断 

    self.m_btn_bigCoins     =   self:findChild("btn_bigCoins")
    self.m_btn_shake        =   self:findChild("btn_shake")
    self.m_btn_wall         =   self:findChild("btn_wall")

    self.m_free_Shake = util_createAnimation("CoinCircus_biaoqian.csb")
    self:findChild("shake_free"):addChild(self.m_free_Shake)
    self:findChild("shake_free"):setVisible(false)
    self.m_free_Shake:runCsbAction("idle",true)
    
    self.m_free_Wall = util_createAnimation("CoinCircus_biaoqian.csb")
    self:findChild("wall_free"):addChild(self.m_free_Wall)
    self:findChild("wall_free"):setVisible(false)
    self.m_free_Wall:runCsbAction("idle",true)

    self.m_free_BigCoins = util_createAnimation("CoinCircus_biaoqian.csb")
    self:findChild("huge_free"):addChild(self.m_free_BigCoins)
    self:findChild("huge_free"):setVisible(false)
    self.m_free_BigCoins:runCsbAction("idle",true)

    self.m_tip = util_createView(Config.ViewPathConfig.PropTipView,self) 
    self:findChild("Node_tip"):addChild(self.m_tip)
    self.m_tip:setVisible(false)
    
    self:addClick(self.m_btn_bigCoins)
    self:addClick(self.m_btn_shake)
    self:addClick(self.m_btn_wall)

    self.m_propName = {}
    self.m_propParentNode = {}
    self.m_vecProps = {}
    util_setCascadeOpacityEnabledRescursion(self,true)
    
end

-- 请求购买道具 select ： 0：震动 ，1墙， 2大金币 
function GamePusherPropView:updateUI(_vec, _outLine)
    self.m_iAllPropsNum = #_vec
    self.m_tip:setVisible(false)
    self.m_tip:removeAllTipWords()

    for key, value in pairs(self.m_vecProps) do
        value:removeFromParent()
        value = nil
    end

    self.m_btn_bigCoins:setVisible(false)
    self.m_btn_shake:setVisible(false)
    self.m_btn_wall:setVisible(false)

    self.m_propName = {}
    self.m_vecProps = {}
    self.m_propParentNode = {}

    for i = 1, #_vec, 1 do
        local info = _vec[i]
        local btnName = VEC_BTN_NAME[i]
        local propInfo = {}
        if info.propName == "wallMaxUseNum" then
            propInfo.path = "CoinCircus_daoju_shouji_wall.csb"
            propInfo.type = 1
        elseif info.propName == "bigCoinMaxUseNum" then
            propInfo.path = "CoinCircus_daoju_shouji_huge.csb"
            propInfo.type = 2
        elseif info.propName == "shakeMaxUseNum" then
            propInfo.path = "CoinCircus_daoju_shouji_shake.csb"
            propInfo.type = 0
        end
        self.m_propName[btnName] = info.propName
        propInfo.propName = info.propName
        propInfo.num = info.num
        local parent = self:findChild(VEC_POS_NAME[i])
        local prop = util_createView("CoinCircusSrc.GamePusherMain.GamePusherProps", propInfo)
        parent:addChild(prop)
        prop:setVisible(_outLine or false)
        self.m_propParentNode[info.propName] = parent
        self.m_vecProps[info.propName] = prop

        self:findChild(btnName):setVisible(true)

        self.m_tip:addTipWords(i, info.propName)
        if _outLine == true then
            self.m_tip:setVisible(true)
            prop:runCsbAction("idle2", true)
        end
    end
    
    self.m_tip:updateUI(self.m_iAllPropsNum)
    
    self:runCsbAction("idle"..self.m_iAllPropsNum)
    self:createJackpotIcon()
    
end

function GamePusherPropView:createJackpotIcon()
    local propInfo = {}   
    propInfo.path = "CoinCircus_daoju_shouji_jackpot.csb"
    local parent = self:findChild(VEC_POS_NAME[self.m_iAllPropsNum + 1])
    local prop = util_createView("CoinCircusSrc.GamePusherMain.GamePusherProps", propInfo)
    parent:addChild(prop)
    self.m_propParentNode["jackpot"] = parent
    self.m_vecProps["jackpot"] = prop
    prop:setVisible(false)
    self.m_jpCollectlab = prop:findChild("propLab")
    self.m_jpCollectDark1   =  prop:findChild("CoinCircus_coin01_dark")
    self.m_jpCollectDark2   =   prop:findChild("CoinCircus_coindi_dark")
end

function GamePusherPropView:showPropIcon(propName)
    local prop = self.m_vecProps[propName]
    if prop:isVisible() == false then
        prop:setVisible(true)
        prop:runCsbAction("actionframe", false, function()
            prop:runCsbAction("idle2", true)
        end)
    end
end

function GamePusherPropView:getPropIconNode(propName)
    local node =  self.m_propParentNode[propName]
    return node
end

function GamePusherPropView:showTip()
    if self.m_iAllPropsNum > 0 then
        self.m_tip:setVisible(true)
    end
end

function GamePusherPropView:clickFunc(sender)
    if self._TouchEnabled == false then
        return
    end

    if self.m_SpecClickEnable == false then
        return
    end

    local btnName = sender:getName()
    
    gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_Click.mp3")  

    self.m_tip:quickCloseTip( )
    self.m_pGamePusherMgr:restSendDt()
    

    -- 请求购买道具 select ： 0：震动 ，1墙， 2大金币 
    local propNum = self.m_pGamePusherMgr:getPropNum(self.m_propName[btnName])
    local type = VEC_PROP_TYPE[self.m_propName[btnName]]

    if propNum == 1 then
        local tip = self:findChild(VEC_PROP_TIP[btnName])
        local prop = self.m_vecProps[self.m_propName[btnName]]
        prop:runCsbAction("idle1", true)
        tip:setVisible(false)
        self:findChild(btnName):setVisible(false)
    end

    if btnName == "btn_bigCoins" then

        
        local time = true
        if propNum > 0 then
            self.m_pGamePusherMgr:upDataPropTouchEnabled(false )
            -- self.m_pGamePusherMgr:requestBonusBuyProp( Config.PropType.BIGCOINS  ) 
            gLobalNoticManager:postNotification(Config.Event.GamePusherUseProp, type)
            -- local aniLightNode = util_createAnimation(Config.UICsbPath.CollectLightCsb)
            -- self:findChild("Node_L_BigCoins"):addChild(aniLightNode)
            -- aniLightNode:runCsbAction("actionframe",false,function(  )
            --     aniLightNode:removeFromParent()
            -- end)
        end
       
    elseif btnName == "btn_wall"  then

        local time = true
        if propNum > 0 then
            
            self.m_pGamePusherMgr:upDataPropTouchEnabled(false )
            -- self.m_pGamePusherMgr:requestBonusBuyProp( Config.PropType.WALL )
            gLobalNoticManager:postNotification(Config.Event.GamePusherUseProp, type)
            -- local aniLightNode = util_createAnimation(Config.UICsbPath.CollectLightCsb)
            -- self:findChild("Node_L_wall"):addChild(aniLightNode)
            -- aniLightNode:runCsbAction("actionframe",false,function(  )
            --     aniLightNode:removeFromParent()
            -- end) 
        end
        
    elseif btnName == "btn_shake"  then
        
        local time = true
        if propNum > 0 then
            
            self.m_pGamePusherMgr:upDataPropTouchEnabled(false )
            -- self.m_pGamePusherMgr:requestBonusBuyProp( Config.PropType.SHAKE )
            gLobalNoticManager:postNotification(Config.Event.GamePusherUseProp, type)
            -- local aniLightNode = util_createAnimation(Config.UICsbPath.CollectLightCsb)
            -- self:findChild("Node_L_shake"):addChild(aniLightNode)
            -- aniLightNode:runCsbAction("actionframe",false,function(  )
            --     aniLightNode:removeFromParent()
            -- end) 
        end
       
    end

end

function GamePusherPropView:setTouchEnabled(_TouchEnabled )
    self._TouchEnabled = _TouchEnabled
end

function GamePusherPropView:onEnter()
    self:registerObserver() 
end

function GamePusherPropView:registerObserver( )
    

    gLobalNoticManager:addObserver( self,function(self, params)                -- 判断玩家当前是否是允许点击的特殊状态（特殊逻辑）
        self.m_SpecClickEnable = params.TouchEnabled
        end, Config.Event.GamePusherMainUI_PropSpecTouchEnabled
    )

    gLobalNoticManager:addObserver( self,function(self, params)                -- 判断玩家当前是否是允许点击的状态（点击道具后）
        self:setTouchEnabled(params.TouchEnabled )
        end, Config.Event.GamePusherMainUI_PropTouchEnabled
    )


    gLobalNoticManager:addObserver( self,function(self, params)                -- 震动道具播放完毕
        self:setTouchEnabled(true )
        end, Config.Event.GamePusherEffect_HammerPlayEnd
    )

    gLobalNoticManager:addObserver( self,function(self, params)                 -- 第二币值更新道具价格


        self.m_tip:quickCloseTip( )

        end,Config.Event.GamePusherMainUI_QuickClosePropTip
    )

    gLobalNoticManager:addObserver( self,function(self, params)                 -- jackpot


        self.m_jpCollectDark1   =  self:findChild("CoinCircus_coin01_dark")
        if self.m_jpCollectDark1 then
            self.m_jpCollectDark1:setVisible(params.nVisible)
        end
        self.m_jpCollectDark2   =   self:findChild("CoinCircus_coindi_dark")
        if self.m_jpCollectDark2 then
            self.m_jpCollectDark2:setVisible(params.nVisible)
        end
        end,Config.Event.GamePusherMainUI_UpdateJPCollectDarkImg
    )

    gLobalNoticManager:addObserver( self,function(self, params)                -- 更新jackpot收集个数
        local isInit = params.nisInit
        local time = params.ntimes
        if isInit then
            if self.m_vecProps["jackpot"] then
                self.m_vecProps["jackpot"]:setVisible(true)
                self.m_jpCollectlab:setString(time)
            end
        else
            local callFunc = function(  )
                if self.m_vecProps["jackpot"] then
                    self.m_vecProps["jackpot"]:setVisible(true)
                    self.m_jpCollectlab:setString(time)
                end
                gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateJPCollectDarkImg,{nVisible = false}) 
            end
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayPropCollectJpCoinsAnim,{nCallFunc = callFunc})   
        end
        if time == 0 then
            if self.m_vecProps["jackpot"] then
                self.m_vecProps["jackpot"]:setVisible(false)
            end
        end

    end, Config.Event.GamePusherMainUI_UpdateJPCollect)

    gLobalNoticManager:addObserver( self,function(self, params)                 -- 道具提示


        self:checkPropNum( )

    end,Config.Event.GamePusherMainUI_PropTip)
    
end

function GamePusherPropView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end


function GamePusherPropView:checkPropNum()
    if self.m_pGamePusherMgr:checkPusherDropTimesUseUp() and self.m_pGamePusherMgr:checkPusherPropUseUp() == false then
        for key, value in pairs(self.m_propName) do
            local propName = value
            local propNum = self.m_pGamePusherMgr:getPropNum(propName)
            local tip = self:findChild(VEC_PROP_TIP[key])
            if propNum > 0 and propName ~= "wallMaxUseNum" and tip:isVisible() == false then
                local prop = self.m_vecProps[propName]
                prop:runCsbAction("idle3", true)

                tip:setVisible(true)
            end
        end
    end
end

return GamePusherPropView