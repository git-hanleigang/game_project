
--[[

--]]
local Activity_GiftCodes = class("Activity_GiftCodes", BaseLayer)

function Activity_GiftCodes:ctor()
    Activity_GiftCodes.super.ctor(self)
    
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName("Activity_GiftCodes/Activity/csb/Activity_GiftCodesLayer.csb")
    self:setExtendData("Activity_GiftCodes")
end

function Activity_GiftCodes:initCsbNodes()
    self.m_lb_desc = self:findChild("lb_desc")
    self.m_textfild = self:findChild("TextField_1")
    self.m_number = self:findChild("lb_number")
    self.m_node_tip = self:findChild("node_tip")
end

function Activity_GiftCodes:initDatas(_data)
    self.m_data = _data    
end

function Activity_GiftCodes:initView()
    self.m_eboxGift = util_convertTextFiledToEditBox(self.m_textfild, nil, function(strEventName,pSender)
        if strEventName == "began" then
            self.m_lb_desc:setVisible(false)
        elseif strEventName == "changed" then
            self:upDateExt()
        elseif strEventName == "return" then
            self:upDateExt()
        end
    end)
    self:setButtonLabelContent("btn_useit","USE IT")
end

function Activity_GiftCodes:upDateExt()
    local text = self.m_eboxGift:getText()
    local sc = string.match(text,"[A-Z0-9]+")
    if not sc then
        self.m_eboxGift:setText("")
        return
    end
    local len = string.len(sc)
    local b = string.sub(sc,len,len)
    if b == "I" or b == "0" or b == "O" or b == "1" then
        sc = string.sub(sc,1,len-1)
    end
    self.m_eboxGift:setText(sc)
end

function Activity_GiftCodes:clickFunc(_sender)
    
    local btnName = _sender:getName()
    if btnName == "btn_close" then
        self:closeUI()
    elseif btnName == "btn_cha" then
        self.m_lb_desc:setVisible(true)
        self.m_eboxGift:setText("")
    elseif btnName == "btn_useit" then
        local code = self.m_eboxGift:getText()
        local s = string.match(code,"^[A-Z0-9]+$")
        if string.len(code) > 10 or string.len(code) == 0 or s == nil then
            self:creatTips(4)
            return
        end
        G_GetMgr(G_REF.GiftCodes):requestExchange(code)
    end
end

function Activity_GiftCodes:registerListener()
    Activity_GiftCodes.super.registerListener(self)
    gLobalNoticManager:addObserver(
        self,
        function(sender, items)
            if items.responseStatus.code ~= 2000 then
                self:setTips(items.responseStatus.code)
                return
            end
            local callback = function()
                if not tolua.isnull(self) then
                    self:closeUI()
                end
            end
            G_GetMgr(G_REF.GiftCodes):showRewardLayer(items,callback)
        end,
        ViewEventType.NOTIFY_GIFTCODE_COLLECT
    )
end

function Activity_GiftCodes:setTips(_code)
    if _code == 2003 then
        self:creatTips(1)
    elseif _code == 2002 then
        self:creatTips(2)
    elseif _code == 2005 then
        self:creatTips(3)
    elseif _code == 2001 then
        self:creatTips(4)
    else
        self:creatTips(1)
    end
end

function Activity_GiftCodes:creatTips(_type)
    if self.m_qipao and not tolua.isnull(self.m_qipao) then
        self.m_qipao:removeFromParent()
        self.m_qipao = nil
    end
    self.m_qipao = util_createView("views.GiftCodes.GiftCodesTips",_type)
    self.m_node_tip:addChild(self.m_qipao)
end

return Activity_GiftCodes
