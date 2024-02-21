--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-03-01 14:18:59
]]

local FoodStreetDoubleWheelView = class("FoodStreetDoubleWheelView", util_require("base.BaseView"))

local OUT_WHEEL_NUM = 8
local IN_WHEEL_NUM = 4

function FoodStreetDoubleWheelView:initUI(data)
    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_show_wheel.mp3")

    self:createCsbNode("FoodStreet_Wheel_sup.csb")

    self.m_bIsTouch = true
    self.m_outWeelIndex = data.wheelIndex + 1
    self.m_inWeelIndex = data.keepShop
    self.m_winCoin = data.wheel[data.wheelIndex + 1]
    self.m_parentLayer = data.parentLayer
    self.m_callback = data.callback

    --wai
    self.m_out_wheel = require("CodeFoodStreetSrc.FoodStreetWheelAction"):create(
        self:findChild("zhuanpan"),
        OUT_WHEEL_NUM,
        function()
            -- 滚动结束调用
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
        end
    )
    self:addChild(self.m_out_wheel)
    self:setOutWheelRotModel()

    local index = 1
    while true do
        local parent = self:findChild("text_" .. index)
        if parent ~= nil then
            local csbName = "FoodStreet_Wheel_super_zi1.csb"
            if index % 2 == 0 then
                csbName = "FoodStreet_Wheel_super_zi.csb"
            end
            local info = {}
            info.name = csbName
            info.coin = data.wheel[index + 1]
            local coinNum = util_createView("CodeFoodStreetSrc.FoodStreetWheelCoin", info)
            parent:addChild(coinNum)
        else
            break
        end
        index = index + 1
    end

    --nei
    self.m_in_wheel = require("CodeFoodStreetSrc.FoodStreetWheelAction"):create(
        self:findChild("xiaozhuanpan"),
        IN_WHEEL_NUM,
        function()
            -- 滚动结束调用
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
        end
    )
    self:addChild(self.m_in_wheel)
    self:setInWheelRotModel()

    self.m_inWheelNode = {}
    self.m_inWheelNode.sp, self.m_inWheelNode.act = util_csbCreate("FoodStreet_Wheel_sup_0.csb")
    self:findChild("xiaozhuanpan"):addChild(self.m_inWheelNode.sp)
    util_csbPlayForKey(self.m_inWheelNode.act,"idle")

    self.m_inWheelLight = {}
    self.m_inWheelLight.sp, self.m_inWheelLight.act = util_csbCreate("FoodStreet_Wheel_sup_1.csb")
    self:findChild("xiaozhuanpanguang"):addChild(self.m_inWheelLight.sp)
    util_csbPlayForKey(self.m_inWheelLight.act,"idle")

    self.m_rowNode = {}
    self.m_rowNode.sp, self.m_rowNode.act = util_csbCreate("FoodStreet_Wheel_zhizhen.csb")
    self:findChild("zhizhen"):addChild(self.m_rowNode.sp)
    util_csbPlayForKey(self.m_rowNode.act,"idle2")

    self:runCsbAction("actionframe", true)
end

function FoodStreetDoubleWheelView:onEnter()

end

function FoodStreetDoubleWheelView:onExit()

end

-- 设置转盘盘滚动参数
function FoodStreetDoubleWheelView:beginOutWheelAction()
    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 500
     --匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 150 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 110 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = function (  )
        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_wheel_stop.mp3")
       
    	self:runCsbAction("zhongjiang", true)

        performWithDelay(self,function (  )
            util_csbPlayForKey(self.m_rowNode.act,"dawn",false,function (  )
                performWithDelay(self,function (  )
                    self:beginInWheelAction()
                end,1)
            end)
        end,1)

    end

    self.m_out_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_out_wheel:beginWheel()

    -- 设置轮盘功能滚动结束停止位置
    self.m_out_wheel:recvData(self.m_outWeelIndex)

    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_wheel_begin.mp3")
end

-- 设置轮盘实时滚动调用
function FoodStreetDoubleWheelView:setOutWheelRotModel()
    self.m_out_wheel:setWheelRotFunc(
        function(distance, targetStep, isBack)
            self:setRotionAction(distance, targetStep, isBack)
        end
    )
end

-- 设置转盘盘滚动参数
function FoodStreetDoubleWheelView:beginInWheelAction()
    
    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 1 --匀速时间
    wheelData.m_slowA = 350 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 100 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 1 --停止圈数
    wheelData.m_randomDistance = 10

    wheelData.m_func = function (  )
        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_wheel_stop.mp3")

        util_csbPlayForKey(self.m_inWheelLight.act,"zhongjiang",true)

        performWithDelay(self,function (  )
            self.m_parentLayer:addSuperWheelWinCoinView(self.m_winCoin,self.m_inWeelIndex,function (  )
                if self.m_callback then
                    self.m_callback()
                end
                self:removeFromParent()
            end)
        end,2)

    end

    self.m_in_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_in_wheel:beginWheel()

    -- 设置轮盘功能滚动结束停止位置
    self.m_in_wheel:recvData(self.m_inWeelIndex)

    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_wheel_begin.mp3")
end

-- 设置轮盘实时滚动调用
function FoodStreetDoubleWheelView:setInWheelRotModel()
    self.m_in_wheel:setWheelRotFunc(
        function(distance, targetStep, isBack)
            self:setRotionAction(distance, targetStep, isBack)
        end
    )
end

function FoodStreetDoubleWheelView:setRotionAction(distance, targetStep, isBack)
    self.distance_now = distance / targetStep

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now

        -- self:runCsbAction("animation0")
        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_wheel_rot.mp3")
    end
end

function FoodStreetDoubleWheelView:clickFunc(sender)
	local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then
    	if self.m_bIsTouch == false then
        	return
    	end

        self.m_bIsTouch = false
        self:runCsbAction("idle")
        self:beginOutWheelAction()
    end
end

return FoodStreetDoubleWheelView