local GamePusherProps = class("GamePusherProps", util_require("base.BaseView"))
local Config              = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")
local GamePusherManager   = require "CoinCircusSrc.GamePusherManager"

local PROP_NAME = 
{
    "wallMaxUseNum",
    "shakeMaxUseNum",
    "bigCoinMaxUseNum"
}

function GamePusherProps:ctor( )
    self.m_pGamePusherMgr  =  GamePusherManager:getInstance()
    GamePusherProps.super.ctor(self )
end

-- 请求购买道具 select ： 0：震动 ，1墙， 2大金币 
function GamePusherProps:initUI(data)
    
    self:createCsbNode(data.path, false)
    self:runCsbAction("idle1")

    self.m_propType = data.type
    self.m_propNum = data.num
    self.m_propName = data.propName

    self.m_labPropNum = self:findChild("propLab")
    
    local wallDown = self:findChild("wall_down")
    if wallDown ~= nil then
        self.m_loading = util_createView(Config.ViewPathConfig.PropLoadingView) 
        self:findChild("wall_down"):addChild(self.m_loading)
        self.m_walllab    =   self.m_loading:findChild("m_lb_num")
    end
    self.m_labPropNum:setString(self.m_propNum)

    util_setCascadeOpacityEnabledRescursion(self,true)

end



function GamePusherProps:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function GamePusherProps:onEnter()

    gLobalNoticManager:addObserver( self,function(self, params)                -- 更新大金币道具个数
    
        end, Config.Event.GamePusherMainUI_UpdateProp_BigCoins
    )

    gLobalNoticManager:addObserver( self,function(self, params)                -- 更新震动道具个数

        end, Config.Event.GamePusherMainUI_UpdateProp_Shake
    )
    
    gLobalNoticManager:addObserver( self,function(self, params)                -- 初始化更新新墙道具个数
        if self.m_loading ~= nil then
            self.m_walllab:setString(math.ceil(params.ntimes) )

            local percent = 0
            if Config.PropWallMaxCount > 0 then
                percent = params.ntimes /  Config.PropWallMaxCount
            end 
        
            self.m_loading:setBarPercent(percent)
            end

        end, 
    Config.Event.GamePusherMainUI_UpdateProp_Wall)

    gLobalNoticManager:addObserver( self,function(self, params)                -- 播放墙进度条动画

        if self.m_loading then
            self.m_loading:runCsbAction(params.nAnimName,params.nIsLoop,params.nCallFunc)
        end
        end, Config.Event.GamePusherMainUI_PlayProp_WallLoadingAni
    )

    gLobalNoticManager:addObserver( self,function(self, params)                 -- 第二币值更新道具价格

        local num = self.m_pGamePusherMgr:getPropNum(self.m_propName)
        local labBg = self:findChild("lab_bg")
        if self.m_propName == "wallMaxUseNum" then
            self.m_labPropNum:setString(num)
            if num == 0 then
                labBg:setVisible(false)
            end
        elseif self.m_propName == "shakeMaxUseNum" then
            self.m_labPropNum:setString(num)
            if num == 0 then
                labBg:setVisible(false)
            end
        elseif self.m_propName == "bigCoinMaxUseNum" then
            self.m_labPropNum:setString(num)
            if num == 0 then
                labBg:setVisible(false)
            end
        end
        
        end,Config.Event.GamePusherMainUI_updatePropPrice
    )
end

return GamePusherProps