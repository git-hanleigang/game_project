--
--大厅关卡容器节点 用来放JACKPOT 或者一列多个关卡情况
--
local LevelRateusNode = class("LevelRateusNode", util_require("base.BaseView"))
LevelRateusNode.m_touch = nil
LevelRateusNode.m_index = nil

function LevelRateusNode:initUI()
    self:createCsbNode("newIcons/Level_Rateus.csb")
    self.m_content = self:findChild("content")
    local size = self.m_content:getContentSize()
    self.m_contentLenX = size.width * 0.5
    self.m_contentLenY = size.height * 0.5
    -- local touch = self:makeTouch(self.m_content)
    -- self:addChild(touch,1)
    -- self:addClick(touch)
    -- self.m_touch = touch
    -- self.m_btn_rateus = self:findChild("btn_rateus")
    -- self.m_btn_rateus:setTouchEnabled(self:isOpenRateus())
    -- self.m_btn_rateus:setVisible(self:isOpenRateus())
end

function LevelRateusNode:isOpenRateus()
    -- local isRateus = gLobalDataManager:getStringByField("LevelRateusNode", "")
    -- if isRateus == "open" then
    --     return false
    -- end
    if self.m_rateUsAction then
        return true
    else
        return false
    end
end

function LevelRateusNode:pushOpenRateus(flag)
    if flag then
        -- self.m_btn_rateus:setTouchEnabled(false)
        -- self.m_btn_rateus:setVisible(false)
        gLobalDataManager:setStringByField("LevelRateusNode", "open")
    else
        -- self.m_btn_rateus:setTouchEnabled(true)
        -- self.m_btn_rateus:setVisible(true)
        gLobalDataManager:setStringByField("LevelRateusNode", "")
    end
end

function LevelRateusNode:getContentLen()
    return self.m_contentLenX, self.m_contentLenY
end

function LevelRateusNode:getOffsetPosX()
    return self.m_contentLenX
end

function LevelRateusNode:updateUI()
end

--根据content大小创建按钮监听
function LevelRateusNode:makeTouch(content)
    local touch = ccui.Layout:create()
    touch:setName("touch")
    touch:setTag(10)
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(true)
    touch:setAnchorPoint(0.5000, 0.5000)
    touch:setContentSize(content:getContentSize())
    touch:setClippingEnabled(false)
    touch:setBackGroundColorOpacity(0)
    return touch
end

--点击回调
function LevelRateusNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    -- if name == "touch" then
    self:clickRateus()
    -- end
end
--点击回调
function LevelRateusNode:MyclickFunc()
    -- if name == "touch" then
    self:clickRateus()
    -- end
end

function LevelRateusNode:clickRateus()
    if self:isOpenRateus() then
        return true
    end
    -- self:pushOpenRateus(true)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self.m_rateUsAction =
        performWithDelay(
        self,
        function()
            -- globalData.rateUsData:checkNetWork()
            -- xcyy.GameBridgeLua:rateUsForSetting()
            globalData.rateUsData:openRateUsView(nil, "RateUs", true)
            self.m_rateUsAction = nil
        end,
        0.2
    )
end

return LevelRateusNode
