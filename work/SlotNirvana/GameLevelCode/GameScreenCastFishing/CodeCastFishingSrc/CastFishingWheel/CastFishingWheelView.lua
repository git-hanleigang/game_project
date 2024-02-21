local CastFishingWheelView = class("CastFishingWheelView", util_require("base.BaseView"))
local SendDataManager = require "network.SendDataManager"
local CastFishingMusicConfig = require "CodeCastFishingSrc.CastFishingMusicConfig"

CastFishingWheelView.m_randWheelIndex = nil
CastFishingWheelView.m_wheelSumIndex =  5 -- 轮盘有多少块
CastFishingWheelView.m_wheelData = {} -- 大轮盘信息
CastFishingWheelView.m_wheelNode = {} -- 大轮盘Node 
CastFishingWheelView.m_bIsTouch = nil

--[[
    _data = {
        jackpotData = {
                amount = 0,
                jackpot = "mini",
                multi = 5,
        }
        overFun = fn,
    }
]]
function CastFishingWheelView:initDatas(_data)
    self.m_bIsTouch = false

    self.m_data = _data
    -- 获取停轮索引
    local wheelList = {
        {1, "grand"},
        {2, "major"},
        {3, "mini"},
        {4, "mega"},
        {5, "minor"},
    }
    local jackpotLineData = self.m_data.jackpotData
    self.m_randWheelIndex = 1
    for i,_config in ipairs(wheelList) do
        if jackpotLineData.jackpot == _config[2] then
            self.m_randWheelIndex =  _config[1]
            break
        end
    end
end

function CastFishingWheelView:initUI()
    self:createCsbNode("CastFishing/CastFishingWheel.csb") 

    self.m_wheel = require("CodeCastFishingSrc.CastFishingWheel.CastFishingWheelAction"):create(
        self:findChild("sp_wheel"),
        self.m_wheelSumIndex,
        -- 滚动结束调用
        function()
        end,
        -- 滚动实时调用
        function(distance,targetStep,isBack)
            self.distance_now = distance / targetStep
    
            if self.distance_now < self.distance_pre then
                self.distance_pre = self.distance_now 
            end
            local floor = math.floor(self.distance_now - self.distance_pre)
            if floor > 0 then
                self.distance_pre = self.distance_now 
            
                -- gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_wheel_rotate.mp3")       
            end
        end
    )
    self:addChild(self.m_wheel)

    self.m_spine = util_spineCreate("Socre_CastFishing_9_tanban",true,true)
    self:findChild("Node_spine"):addChild(self.m_spine)

    self.m_fankuiCsb = util_createAnimation("CastFishing_zhuanpanfankui.csb")
    self:findChild("Node_fankui"):addChild(self.m_fankuiCsb)
    self.m_fankuiCsb:setVisible(false)

    self.m_btnEffectCsb = util_createAnimation("CastFishing_zhuanpanainiu.csb")
    self:findChild("anniu"):addChild(self.m_btnEffectCsb)
    self.m_btnEffectCsb:setVisible(false)

    self:addClick(self:findChild("Panel_click"))
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:playStartAnim()
end

function CastFishingWheelView:playStartAnim()
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
    util_spinePlay(self.m_spine, "zhuanpan_start", false)
    util_spineEndCallFunc(self.m_spine, "zhuanpan_start", function()
        util_spinePlay(self.m_spine, "zhuanpan_idle", true)
        self.m_bIsTouch = true
    end) 
end
function CastFishingWheelView:playOverAnim()
    if self.m_rotationSoundId then
        gLobalSoundManager:stopAudio(self.m_rotationSoundId)
        self.m_rotationSoundId = nil
    end
    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_jackpotWheel_winEffect)

    self.m_fankuiCsb:setVisible(true)
    self.m_fankuiCsb:runCsbAction("fankui", true)
    -- 向上看
    util_spinePlay(self.m_spine, "zhuanpan_idle4", false)
    util_spineEndCallFunc(self.m_spine, "zhuanpan_idle4", function()
        util_spinePlay(self.m_spine, "zhuanpan_idle", true)
    end) 
    -- 播3次反馈
    local fankuiTime = util_csbGetAnimTimes(self.m_fankuiCsb.m_csbAct, "fankui")
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_jackpotWheel_over)
        self.m_fankuiCsb:setVisible(false)
        self:runCsbAction("over", false, function()
            self.m_data.overFun()
            self:removeFromParent()
        end)

        waitNode:removeFromParent()
    end, fankuiTime*3) 
end



function CastFishingWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end
    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_jackpotWheel_click)

    self.m_bIsTouch = false
    self:findChild("btn_spin"):setEnabled(false)

    self.m_btnEffectCsb:setVisible(true)
    self.m_btnEffectCsb:runCsbAction("tishi", false, function()
        self.m_btnEffectCsb:setVisible(false)
    end)

    --章鱼反馈 6帧开始旋转
    util_spinePlay(self.m_spine, "zhuanpan_idle2", false)
    util_spineEndCallFunc(self.m_spine, "zhuanpan_idle2", function()
        util_spinePlay(self.m_spine, "zhuanpan_idle3", true)
    end) 
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        self.m_rotationSoundId = gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_jackpotWheel_rotation, true)
        self:beginWheelAction()

        waitNode:removeFromParent()
    end, 3/30) 
end


-- 设置转盘盘滚动参数
function CastFishingWheelView:beginWheelAction()
    local wheelData = {}
    wheelData.m_startA         = 150  --加速度
    wheelData.m_runV           = 400  --匀速
    wheelData.m_runTime        = 3    --匀速时间
    wheelData.m_slowA          = 50   --动态减速度
    wheelData.m_slowQ          = 1    --减速圈数
    wheelData.m_stopV          = 100   --停止时速度
    wheelData.m_backTime       = 0    --回弹前停顿时间
    wheelData.m_stopNum        = 0    --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = function()
        self:playOverAnim()
    end

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()
    -- 设置轮盘功能滚动结束停止位置
    self.m_wheel:recvData(self.m_randWheelIndex)
end

return CastFishingWheelView