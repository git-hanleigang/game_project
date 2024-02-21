
-- 聊天信息公共类 处理一些公共逻辑

local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanChatMessageBase = class("ClanChatMessageBase", util_require("base.BaseView"))

ClanChatMessageBase.item_offset2Edge = 20  -- 距离边界的偏移值
ClanChatMessageBase.info_offset = 40  -- 名字和时间之间的空隙

function ClanChatMessageBase:initUI( data )
    self.m_bLoadHead = false

    self:setData(data)

    local csbName = self:getCsbPath()
    if csbName then
        self:createCsbNode(csbName)
        self:readNodes()
        self:updateUI()
    end
end

function ClanChatMessageBase:readNodes()
    self.spHead = self:findChild("sp_touxiang")
    assert(self.spHead, "ClanChatMessageBase 必要的节点1")

    self.sp_qipao = self:findChild("sp_qipao")          -- 背景框
    assert(self.sp_qipao, "ClanChatMessageBase 必要的节点2")

    self.font_name = self:findChild("font_name")        -- 聊天人名字
    assert(self.font_name, "ClanChatMessageBase 必要的节点3")

    self.font_time = self:findChild("font_time")        -- 发送时间
    assert(self.font_time, "ClanChatMessageBase 必要的节点4")

    self.font_word = self:findChild("font_word")        -- 内容
    assert(self.font_word, "ClanChatMessageBase 必要的节点1")
    
    self.bubbleBgSize = self.sp_qipao:getContentSize()
    -- 记录初始位置 框变了以后需要重排
    self.font_name_posy = self.font_name:getPositionY()
    self.font_time_posy = self.font_time:getPositionY()
    self.font_word_posy = self.font_word:getPositionY()

    if self:isMyMessage() then
        self.sp_qipao:setAnchorPoint(cc.p(1,1))
    else
        self.sp_qipao:setAnchorPoint(cc.p(0,1))
    end
end

function ClanChatMessageBase:setData( data )
    if not data then
        return
    end
    self.data = data
end

function ClanChatMessageBase:getMessageId()
    return self.data.msgId
end

function ClanChatMessageBase:getCsbPath()
    assert(false, "子类需要重写方法 getCsbPath")
end

-- 设置玩家头像
function ClanChatMessageBase:setHeadIcon()
    local head = 0
    if string.len(self.data.head) > 0 then
        head = self.data.head
    end
    if self:isMyMessage() and globalData.userRunData.HeadName ~= head then
        head = globalData.userRunData.HeadName 
    end
    if self.m_bLoadHead and self.data.facebookId == self.m_preFbId and head == self.m_preHead and self.data.frameId == self.m_preFrameId then
        return
    end
    self.m_preFbId = self.data.facebookId
    self.m_preHead = head
    self.m_preFrameId = self.data.frameId
    self.spHead:removeAllChildren()
    local headSize = self.spHead:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(self.m_preFbId, self.m_preHead, self.m_preFrameId, nil, headSize)
    nodeAvatar:addTo(self.spHead)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )

    if not self.m_bLoadHead and self:isMyMessage() then
        gLobalNoticManager:addObserver(self, "setHeadIcon", ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER)
    end
    self.m_bLoadHead = true
    
    --增加一个点击头像layout
    local layout = ccui.Layout:create()
    layout:setName("layout_touch")
    layout:setTouchEnabled(true)
    layout:setContentSize(headSize)
    self:addClick(layout)
    layout:addTo(self.spHead)
end

function ClanChatMessageBase:updateUI()
    self:setHeadIcon()
    self:resetNameStr()
    self:resetTimer()
    self:updateContent()
    self:resetPosition()
end

function ClanChatMessageBase:resetNameStr()
    local defaule_name = ""
    if self:isMyMessage() then
        defaule_name = "YOU"
    else
        defaule_name = self.data.nickname or "SOMEONE"
    end
    self.font_name:setString(defaule_name)
end

function ClanChatMessageBase:resetTimer()
    local tm = os.date("*t", self.data.sendTime/1000)
    -- local tm = util_UTC2TZ(self.data.sendTime/1000, -8)
    local cur_tm = util_formatServerTime()
    local day = ""
    if cur_tm.day ~= tm.day then
        day = tm.month .. "/" .. tm.day .. "  "
    end
    local hour = tm.hour
    if tm.hour < 10 then
        hour = "0" .. tm.hour
    end
    local min = tm.min
    if tm.min < 10 then
        min = "0" .. tm.min
    end
    local sec = tm.sec
    if tm.sec < 10 then
        sec = "0" .. tm.sec
    end
    self.font_time:setString( day .. hour .. ":" .. min .. ":" .. sec )
end

function ClanChatMessageBase:updateContent( )
    assert(false, "updateContent 需要子类重写 加载自身内容")
end

-- 文本信息区域大小
function ClanChatMessageBase:getInnerSize( )
    assert(false, "getInnerSize 需要子类重写 获取文本区域大小")
end

function ClanChatMessageBase:getBubbleSize()
    local content_size = self:getInnerSize()
    -- 计算文本显示区域
    content_size.width = content_size.width + self.item_offset2Edge * 2
    content_size.height = content_size.height + self.item_offset2Edge + (self.bubbleBgSize.height - self.font_word_posy)

    local name_width = self.font_name:getContentSize().width * self.font_name:getScaleX()
    local time_width = self.font_time:getContentSize().width * self.font_time:getScaleX()
    local info_width = name_width + time_width + self.info_offset + self.item_offset2Edge * 2
    if content_size.width < info_width then
        content_size.width = info_width
    end
    return content_size
end

function ClanChatMessageBase:resetPosition()
    local content_size = self:getBubbleSize()

    local height_offset = self:getHeightOffset()
    -- 背景框要随着文本长度变化
    -- 重置背景框大小
    self.sp_qipao:setContentSize( content_size )
    -- 背景框变了 位置都得重新排布 主要是因为背景框的放大是向负x轴伸展的 效果在studio里就能看出来
    -- 重置名称位置
    self.font_name:setPositionX(self.item_offset2Edge)
    self.font_name:setPositionY(height_offset + self.font_name_posy)

    -- 重置时间位置
    self.font_time:setPositionX(content_size.width - self.item_offset2Edge)
    self.font_time:setPositionY(height_offset + self.font_time_posy)

    -- 重置文本位置
    self.font_word:setPositionX(self.item_offset2Edge)
    self.font_word:setPositionY(height_offset + self.font_word_posy)
end

function ClanChatMessageBase:getHeightOffset()
    local content_size = self:getBubbleSize()
    return content_size.height - self.bubbleBgSize.height
end

function ClanChatMessageBase:getWidthOffset()
    local content_size = self:getBubbleSize()
    return content_size.width - self.bubbleBgSize.width
end

function ClanChatMessageBase:isMyMessage()
    if self.data and self.data.sender == globalData.userRunData.userUdid then
        return true
    end
    return false
end

function ClanChatMessageBase:getContentSize()
    local pos_x = self.sp_qipao:getPositionX()
    local bg_size = self.sp_qipao:getContentSize()
    return {width = bg_size.width + math.abs(pos_x), height = bg_size.height}
end

-- 子类从写 定时器一秒调用一次
function ClanChatMessageBase:updateUISec()
end

function ClanChatMessageBase:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
       if self.data.sender == globalData.userRunData.userUdid then
           G_GetMgr(G_REF.UserInfo):showMainLayer()
       else
           G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.data.sender, "","",self.data.frameId)
       end
    end
end

return ClanChatMessageBase