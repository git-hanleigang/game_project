--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-17 19:41:01
    describe:小猪转盘-轮盘
]]
local GoodWheelPiggyWheel = class("GoodWheelPiggyWheel", BaseView)
local GoodWheelPiggyAction = require("activities.Activity_GoodWheelPiggy.view.GoodWheelPiggyAction")

function GoodWheelPiggyWheel:ctor()
    GoodWheelPiggyWheel.super.ctor(self)
    self.m_data = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getRunningData()
    self.m_config = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getConfig()
end

function GoodWheelPiggyWheel:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_btnSpin:setEnabled(false)
            local data = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getRunningData()
            local seq = data:getSeq()
            self:beginWheelAction(seq)
        end,
        ViewEventType.NOTIFY_GOODWHEELPIGGY_REQUEST_SPIN_SUCESS
    )
end

function GoodWheelPiggyWheel:getCsbName()
    return self.m_config.Wheel
end

function GoodWheelPiggyWheel:initUI(data)
    self.m_param = data
    GoodWheelPiggyWheel.super.initUI(self, data)
    self:initView()
end

function GoodWheelPiggyWheel:initCsbNodes()
    self.m_nodeSlide = self:findChild("node_slide")
    assert(self.m_nodeSlide, "GoodWheelPiggyWheel 必要的节点1")
    self.m_btnSpin = self:findChild("btn_spin")
    assert(self.m_btnSpin, "GoodWheelPiggyWheel 必要的节点2")
end

function GoodWheelPiggyWheel:initView()
    self:runCsbAction("idle", true)
    self:initWheelRotation()
    self:initSlide()
    self:initWheel()
    local isVis = self.m_data:checkIsReconnectPop()
    self.m_btnSpin:setEnabled(isVis)
end

-- 初始化扇叶
function GoodWheelPiggyWheel:initSlide()
    self.m_slideList = {}
    local len = self.m_data:getRewardNum()
    for i = 1, len do
        local view = util_createView("activities.Activity_GoodWheelPiggy.view.GoodWheelPiggySlide", i)
        if view then
            local rotation = self.m_nodeSlide:getRotation()
            local angle = 360 / len * i
            view:addTo(self.m_nodeSlide)
            view:setRotation(angle)
            view:setSelectRotation(-angle - rotation)
            table.insert(self.m_slideList, view)
        end
    end
end

-- 初始化轮盘角度
function GoodWheelPiggyWheel:initWheelRotation()
    local lastSeq = self.m_data:getLastSeq()
    local len = self.m_data:getRewardNum()
    local bigIndex = self.m_data:getBigIndex()
    local angle = bigIndex * (360 / len)
    if lastSeq and lastSeq > 0 then
        angle = lastSeq * (360 / len)
    end
    self.m_nodeSlide:setRotation(-angle)
end

-- 初始化轮盘Action
function GoodWheelPiggyWheel:initWheel()
    self.m_wheel =
        GoodWheelPiggyAction:create(
        self.m_nodeSlide,
        self.m_data:getRewardNum(),
        function()
            -- 滚动结束调用
            gLobalSoundManager:playSound(self.m_config.SoundWheelSelect)
            local data = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getRunningData()
            local seq = data:getSeq()
            local slide = self.m_slideList[seq]
            slide:playStart()
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
            if not self.distance then
                self.distance = distance
            else
                local angle = 360 / self.m_data:getRewardNum()
                if math.abs(distance - self.distance) >= angle then
                    self.distance = distance
                    gLobalSoundManager:playSound(self.m_config.SoundWheelRun)
                end
            end
            for i, view in ipairs(self.m_slideList) do
                local len = self.m_data:getRewardNum()
                local angle = 360 / len * i
                view:setSelectRotation(-angle - distance)
            end
        end,
        nil,
        nil
    )
    self:addChild(self.m_wheel)
end

function GoodWheelPiggyWheel:clickFunc(e)
    local name = e:getName()
    if name == "btn_spin" then
        G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):requestSpin()
    end
end

function GoodWheelPiggyWheel:beginWheelAction(index)
    self.m_wheel:recvData(index)
    self.m_wheel:beginWheel()
end

return GoodWheelPiggyWheel
