--[[
    npc气泡
    规则：
    进入关卡后自动弹出，1S后自动消失，会玩家点击屏幕任意区域消失。
    文案一【在第1关出现】
    PICK YOUR CHEST!
    文案二【在第5、10、15关出现】
    YOU'RE SAFE NOW!
    FIND THE GREAT REWARDS!
    文案三【第6、11、16关出现】
    WATCH OUT THE GUARD!
    文案四【第20关（最后一关出现）】
    GREAT!
    THIS IS THE FINAL STAGE!

    优化：
    将气泡的弹出时机从固定关卡弹出改到根据具体关卡弹出。
    ①在特殊关卡弹出原来在第【5、10、15关】出现的YOU'RE SAFE NOW!
    FIND THE GREAT REWARDS!
    ②在最后一关弹出原来在第【20关】出现的：GREAT!
    THIS IS THE FINAL STAGE!
    ③特殊关卡后的第一关弹出原来在第【6、11、16关】出现的：WATCH OUT THE GUARD!    
]]
local CSMainBubble = class("CSMainBubble", BaseView)

function CSMainBubble:getCsbName()
    return CardSeekerCfg.csbPath .. "Seeker_Bubble_Tips.csb"
end

function CSMainBubble:initDatas()
end

function CSMainBubble:initCsbNodes()
    self.m_imgBg = self:findChild("img_bg")
    self.m_lbText1 = self:findChild("Text_1")
    self.m_lbText2 = self:findChild("Text_2")
    self.m_lbText3 = self:findChild("Text_3")
end

function CSMainBubble:initUI()
    CSMainBubble.super.initUI(self)
end

-- -- 点击任意区域气泡消失
-- function CSMainBubble:initMask()
--     if not self.m_layout then
--         self.m_layout = self:createLayout()
--     end
--     self.m_layout:setTouchEnabled(true)
--     self.m_layout:setSwallowTouches(false)
--     self:addClick(self.m_layout)
-- end

-- function PokerGuideUI:createLayout()
--     local tLayout = ccui.Layout:create()
--     gLobalViewManager:getViewLayer():addChild(tLayout, ViewZorder.ZORDER_SPECIAL)
--     tLayout:setName("touch")
--     tLayout:setTouchEnabled(false)
--     tLayout:setAnchorPoint(cc.p(0.5, 0.5))
--     tLayout:setContentSize(cc.size(display.width, display.height))
--     tLayout:setClippingEnabled(false)
--     tLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
--     tLayout:setBackGroundColor(cc.c3b(0, 0, 0))
--     tLayout:setBackGroundColorOpacity(0)
--     return tLayout
-- end

function CSMainBubble:initText(_txtStrs)
    self.m_lbText1:setVisible(false)
    self.m_lbText2:setVisible(false)
    self.m_lbText3:setVisible(false)
    if not _txtStrs then
        return
    end
    local txtWidth = 0
    if _txtStrs and #_txtStrs > 0 then
        if #_txtStrs == 1 then
            self.m_lbText3:setVisible(true)
            self.m_lbText3:setString(_txtStrs[1])
            local txtSize = self.m_lbText3:getContentSize()
            txtWidth = txtSize.width
        elseif #_txtStrs == 2 then
            self.m_lbText1:setVisible(true)
            self.m_lbText2:setVisible(true)
            self.m_lbText1:setString(_txtStrs[1])
            self.m_lbText2:setString(_txtStrs[2])
            local txtSize1 = self.m_lbText1:getContentSize()
            local txtSize2 = self.m_lbText2:getContentSize()
            txtWidth = math.max(txtSize2.width, txtSize1.width)
        end
    end
    local size = self.m_imgBg:getContentSize()
    txtWidth = math.max(340, txtWidth)
    self.m_imgBg:setContentSize(cc.size(txtWidth, size.height))
end

function CSMainBubble:onEnter()
    CSMainBubble.super.onEnter(self)
end

function CSMainBubble:showBubble(_txtStrs, _over)
    self:initText(_txtStrs)
    self:runCsbAction(
        "start",
        false,
        function()
            if not tolua.isnull(self) then
                self:runCsbAction("idle", true, nil, 60)
                util_performWithDelay(
                    self,
                    function()
                        if not tolua.isnull(self) then
                            self:runCsbAction("over", false, _over, 60)
                        end
                    end,
                    2.5
                )
            end
        end,
        60
    )
end

return CSMainBubble
