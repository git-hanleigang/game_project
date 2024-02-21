--常用头像选择页
local FrameDisyLayer = class("FrameDisyLayer", BaseLayer)
function FrameDisyLayer:ctor(_type)
    FrameDisyLayer.super.ctor(self)
    self:setExtendData("FrameDisyLayer")
    local path = "Activity/csd/Information_FramePartII/FramePartII_display/FramePartII_Show.csb"
    self:setLandscapeCsbName(path)
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
end

function FrameDisyLayer:initCsbNodes()
    self.lb_selected = self:findChild("lb_selected")
    self.lb_empty = self:findChild("lb_empty")
end

function FrameDisyLayer:initView()
    local cf_data = G_GetMgr(G_REF.AvatarFrame):getUserHoldFrameIdList()
    if cf_data and #cf_data > 0 then
        self.lb_empty:setVisible(false)
    else
        self.lb_empty:setVisible(true)
    end
    local frame_data = G_GetMgr(G_REF.AvatarFrame):getUserLikeFrameList()
    local selet = 0
    if frame_data and #frame_data > 0 then
        selet = #frame_data
        self.ManGer:clearDisy(frame_data)
    end
    local str = "SELECTED ("..selet.."/3)"
    self.lb_selected:setString(str)
    local table_layer = self:findChild("table_layer")
    local size = table_layer:getContentSize()
    local posx = table_layer:getPositionX()
    local posy = table_layer:getPositionY()
    local param = {
        tableSize = size,
        parentPanel = self:findChild("node_table"),
        directionType = 2,
        showScroll = true,
        padding = 5
    }
    self.m_avterView = util_require("views.UserInfo.view.UserPerson.FrameTableView").new(param)
    self:findChild("node_table"):addChild(self.m_avterView)
    self.m_avterView:setPosition(-size.width/2,-size.height/2)
    self.m_avterView:setVisible(false)
    if cf_data and #cf_data > 0 then
        self.m_avterView:setVisible(true)
        self.m_avterView:reload(cf_data,2)
    end
end

function FrameDisyLayer:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:closeUI()
        end,
        self.config.ViewEventType.FRAME_LIKE_SELECT
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local data = self.ManGer:getDisyItem()
            local num = 0
            for i,v in ipairs(data) do
                if v and v ~= 0 then
                    num = num + 1
                end
            end
            local str = "SELECTED ("..num.."/3)"
            self.lb_selected:setString(str)
        end,
        self.config.ViewEventType.FRAME_AVMENT_ANILEVEL
    )
end


function FrameDisyLayer:clickStartFunc(sender)
end

function FrameDisyLayer:closeUI()
    self.ManGer:clearDisy(nil)
    FrameDisyLayer.super.closeUI(self)
end

function FrameDisyLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_save" then
        --保存
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local select_data = self.ManGer:getDisyItem()
        local frames = {}
        for i=1,3 do
            if select_data[i] and select_data[i] ~= 0 then
                table.insert(frames,tostring(select_data[i]))
            end
        end
        self.ManGer:sendFrameLikenReq(frames)
    end
end

return FrameDisyLayer