--[[
    电话区号
    author:{author}
    time:2022-11-15 20:03:23
]]
local BindPhoneAreaTable = require("views.BindPhone.BindPhoneAreaTable")
local BindPhoneAreaNode = class("BindPhoneAreaNode", BaseView)

function BindPhoneAreaNode:initUI()
    self:createCsbNode("Dialog/BindPhone_code.csb")

    -- local tbDatas = {}
    -- for i = 99, 1, -1 do
    --     local _strCode = string.format("%+2d", i)
    --     table.insert(tbDatas, _strCode)
    -- end
    -- self.m_tbDatas = tbDatas
    self.m_tbDatas = G_GetMgr(G_REF.BindPhone):getAreaData()
    self.m_tbAreaCodes:reload(self.m_tbDatas)
    self:setAreaCode(1)
    self.m_btnChoose:setRotation(90)

    -- 监测互斥的方案 --
    self.m_moveTable = true
    self.m_moveSlider = true

    self:_initSlider()
    self.m_tbAreaCodes._unitTableView:registerScriptHandler(handler(self, self.scrollViewDidScroll), cc.SCROLLVIEW_SCRIPT_SCROLL)
end

function BindPhoneAreaNode:initCsbNodes()
    self.m_nodeCodes = self:findChild("Node_codes")
    self.m_nodeCodes:setVisible(false)
    self.m_spCodeBg = self:findChild("sp_code_xiala_bg")
    self.m_slider = self:findChild("slider")
    -- self.m_slider:setVisible(false)
    -- self.m_slider:registerControlEventHandler(handler(self, self.sliderMoveEvent), cc.CONTROL_EVENTTYPE_VALUE_CHANGED)
    self.m_slider:addEventListenerSlider(handler(self, self.sliderMoveEvent))
    local _tbCodes = self:findChild("tb_codes")
    -- tableView
    self.m_tbAreaCodes =
        BindPhoneAreaTable:create(
        {
            parentPanel = _tbCodes,
            tableSize = _tbCodes:getContentSize(),
            directionType = 2
        }
    )
    _tbCodes:addChild(self.m_tbAreaCodes)
    self.m_tbCodes = _tbCodes

    self.m_btnChoose = self:findChild("btn_choose")
    self.m_lbCode = self:findChild("lb_code")
    self.m_lbCode:setString("")
end

function BindPhoneAreaNode:onEnter()
    -- 显示段位列表变化动画
    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            local idx = param.index
            self:setAreaCode(idx)
            self:closeCodeChooseView()
        end,
        "notify_choose_areaCode"
    )
end

function BindPhoneAreaNode:setAreaCode(idx)
    idx = idx or 0
    local areaInfo = self.m_tbDatas[idx] or ""
    self.m_lbCode:setString("+" .. areaInfo.code)
end

function BindPhoneAreaNode:getAreaCode()
    return self.m_lbCode:getString()
end

function BindPhoneAreaNode:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_choose" then
        if not self.m_nodeCodes:isVisible() then
            self:showCodeChooseView()
        else
            self:closeCodeChooseView()
        end
    end
end

function BindPhoneAreaNode:showCodeChooseView()
    self.m_btnChoose:setRotation(-90)
    self.m_nodeCodes:setVisible(true)
    local _lay = self.m_nodeCodes:getChildByName("blockLayer")
    if not _lay then
        _lay = display.newLayer()
        _lay:setName("blockLayer")
        _lay:onTouch(
            function()
                self:closeCodeChooseView()
                return true
            end,
            false,
            true
        )
        self.m_nodeCodes:addChild(_lay, -1)
    end
end

function BindPhoneAreaNode:closeCodeChooseView()
    self.m_btnChoose:setRotation(90)
    self.m_nodeCodes:setVisible(false)
    self.m_nodeCodes:removeChildByName("blockLayer")
end

function BindPhoneAreaNode:_initSlider()
    local _dis = self.m_tbAreaCodes:_getTabletotalHeight() - self.m_tbCodes:getContentSize().height
    if _dis > 0 then
        self.m_slider:setVisible(true)
        local valueMin = -_dis
        -- self.m_slider:setMinimumValue(valueMin)
        -- self.m_slider:setMaximumValue(0)
        -- self.m_slider:setValue(valueMin)
        self.m_slider:setMaxPercent(_dis)
        self.m_slider:setPercent(0)
    else
        self.m_slider:setVisible(false)
    end
end

-- slider 滑动事件 --
function BindPhoneAreaNode:sliderMoveEvent()
    self.m_moveTable = false
    if self.m_moveSlider == true then
        -- local sliderOff = self.m_slider:getValue()
        -- self.m_tbAreaCodes._unitTableView:setContentOffset(cc.p(0, sliderOff))
        local sliderOff = self.m_slider:getPercent()
        local maxOff = self.m_slider:getMaxPercent()
        self.m_tbAreaCodes._unitTableView:setContentOffset(cc.p(0, sliderOff - maxOff))
    end
    self.m_moveTable = true
end

--滚动事件
function BindPhoneAreaNode:scrollViewDidScroll(view)
    self.m_moveSlider = false

    if self.m_moveTable == true then
        if self.m_slider ~= nil then
            local offY = self.m_tbAreaCodes._unitTableView:getContentOffset().y
            local maxOff = self.m_slider:getMaxPercent()
            -- self.m_slider:setValue(offY)
            self.m_slider:setPercent(maxOff + offY)
        end
    end
    self.m_moveSlider = true
end

return BindPhoneAreaNode
