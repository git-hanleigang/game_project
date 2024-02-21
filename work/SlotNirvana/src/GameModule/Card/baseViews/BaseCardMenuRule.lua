--[[
    卡片收集规则界面  一些玩法说明 --
]]
local BaseCardMenuRule = class("BaseCardMenuRule", BaseLayer)

function BaseCardMenuRule:initDatas()
    self:setPauseSlotsEnabled(true)
end

-- 初始化UI --
function BaseCardMenuRule:initUI(_isSourceDisEnabled)
    self.m_isSourceDisEnabled = _isSourceDisEnabled
    BaseCardMenuRule.super.initUI(self)

    self:initAdapt()
end

function BaseCardMenuRule:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    BaseCardMenuRule.super.playShowAction(self, "show", false)
end

function BaseCardMenuRule:playHideAction()
    gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
    BaseCardMenuRule.super.playHideAction(self, "over", false)
end

function BaseCardMenuRule:onShowedCallFunc()
    if not self.m_isSourceDisEnabled then
        CardSysManager:hideRecoverSourceUI()
    end
    self:runCsbAction("idle")
end

function BaseCardMenuRule:initAdapt()
end

-- 初始化数据 --
function BaseCardMenuRule:initCsbNodes()
    self.m_layerLeft = self:findChild("layer_left")
    self.m_layerRight = self:findChild("layer_right")
    self:addClick(self.m_layerLeft)
    self:addClick(self.m_layerRight)

    --
    self.m_prePage = self:findChild("Button_6")
    self.m_nextPage = self:findChild("Button_7")

    self:initTotalList()

    -- 获取显示列表 --
    self:initShowRuleList()
    self:initPageData()

    self:initTouchLayoutPage()
end

function BaseCardMenuRule:initTotalList()
    self.m_totalRuleList = {}

    local tempIdx = 1
    local rule = self:findChild("rule_" .. tempIdx)
    while rule do
        self.m_totalRuleList[#self.m_totalRuleList + 1] = rule
        tempIdx = tempIdx + 1
        rule = self:findChild("rule_" .. tempIdx)
    end

    for i = 1, #self.m_totalRuleList do
        self.m_totalRuleList[i]:setVisible(false)
    end
end

function BaseCardMenuRule:initShowRuleList()
    self.m_showRuleList = self.m_totalRuleList
end

function BaseCardMenuRule:initPageData()
    self.m_curIndex = 1
    self:showCurRule(self.m_curIndex)
end

-- 点击事件 --
function BaseCardMenuRule:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_4" then
        self:clickExitBtn()
    elseif name == "Button_5" then
        self:clickBackBtn()
    elseif name == "Button_6" or name == "layer_left" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showNextRule(-1)
    elseif name == "Button_7" or name == "layer_right" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showNextRule(1)
    end
end

function BaseCardMenuRule:clickExitBtn()
    self:closeUI()
    if not self.m_isSourceDisEnabled then
        CardSysManager:showRecoverSourceUI()
    end
    -- CardSysManager:closeRecoverSourceUI()
    -- CardSysRuntimeMgr:setSelAlbumID(CardSysRuntimeMgr:getCurAlbumID())
end

function BaseCardMenuRule:clickBackBtn()
    self:closeUI()
    if not self.m_isSourceDisEnabled then
        CardSysManager:showRecoverSourceUI()
    end
end

--
function BaseCardMenuRule:showCurRule(nIndex)
    -- 显示下一个 --
    self.m_showRuleList[nIndex]:setVisible(true)

    if nIndex == 1 then
        self.m_prePage:setVisible(false)
        self.m_layerLeft:setVisible(false)
    else
        self.m_prePage:setVisible(true)
        self.m_layerLeft:setVisible(true)
    end

    if nIndex == #self.m_showRuleList then
        self.m_nextPage:setVisible(false)
        self.m_layerRight:setVisible(false)
    else
        self.m_nextPage:setVisible(true)
        self.m_layerRight:setVisible(true)
    end
end

-- 显示下一个 --
function BaseCardMenuRule:showNextRule(nOff)
    if not self.m_bScrolling then
        local nextIndex = 0
        if nOff < 0 then
            nextIndex = self.m_curIndex - 1
            if nextIndex < 1 then
                return
            end
        elseif nOff > 0 then
            nextIndex = self.m_curIndex + 1
            if nextIndex > #self.m_showRuleList then
                return
            end
        end

        if nextIndex == 0 then
            return
        end

        -- 隐藏当前 --
        self.m_showRuleList[self.m_curIndex]:setVisible(false)
        self.m_curIndex = nextIndex
        self:showCurRule(nextIndex)

        self.m_bScrolling = true
        performWithDelay(
            self,
            function()
                self.m_bScrolling = false
            end,
            0.5
        )
    end
end

-- 关闭事件 --
function BaseCardMenuRule:closeUI(exitFunc)
    local callback = function()
        if exitFunc then
            exitFunc()
        end
    end
    BaseCardMenuRule.super.closeUI(self, callback)
end

function BaseCardMenuRule:initTouchLayoutPage()
    -- 注册滑动和点击区域 --
    local touch = ccui.Layout:create()
    touch:setName("midTouchArea")
    touch:setTag(10)
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(false)
    touch:setAnchorPoint(0.5000, 0.5000)
    touch:setContentSize(1000, 500)
    touch:setPosition(cc.p(display.cx, display.cy))
    touch:setClippingEnabled(false)
    touch:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    touch:setBackGroundColor(cc.c4b(255, 255, 255))
    touch:setBackGroundColorOpacity(0)

    self:addChild(touch)
    -- 添加触摸事件 --
    self:addClick(touch)
end

--移动监听
function BaseCardMenuRule:clickMoveFunc(sender)
    local name = sender:getName()
    if name == "midTouchArea" then
        local beginPos = sender:getTouchBeganPosition()
        local movePos = sender:getTouchMovePosition()
        local moveDis = movePos.x - beginPos.x
        local offx = math.abs(moveDis)
        if offx > 100 then
            self:showNextRule(-moveDis)
        end
    end
end

return BaseCardMenuRule
