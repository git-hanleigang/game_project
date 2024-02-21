
--收藏关卡大厅节点
local CollectTip = class("CollectTip", util_require("base.BaseView"))

function CollectTip:initUI()
    self:createCsbNode("CollectionLevel/csd/Activity_CollectionLevel_loading.csb")
    self:initView()
end

function CollectTip:initCsbNodes()
    self.m_sphome = self:findChild("spr_home")
    self.m_spfv = self:findChild("spr_fov")
    self.m_spslot = self:findChild("spr_cla")
    self.m_spframe = self:findChild("spr_fra")
    self.m_homepao = self:findChild("node_return")
    self.m_fvpao = self:findChild("node_favorite")
    self.m_nodeframe = self:findChild("node_frame")
    self.m_nodeclassic = self:findChild("node_classic")
    self.m_nodeTable = self:findChild("node_table")
end

function CollectTip:initView()
    self.m_spList = {self.m_sphome,self.m_spfv,self.m_spframe,self.m_spslot}
    self:registerListener()
    self.m_status = 1 --1是大厅状态,2是收藏状态,3头像框，4 othergame
    self.m_view = G_GetMgr(G_REF.CollectLevel):createColLevelTbView()
    self.m_nodeTable:addChild(self.m_view)
    self.m_view:setVisible(false)
end

function CollectTip:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local name = sender:getName()
    if name == "btn_favorite" then
        if self.m_status == 2 then
            return
        end
        --打开收藏
        self.m_status = 2
        self:setSpVisible(2)
        self.m_view:updataList()
        self.m_view:setVisible(true)
        if self.motf_vie then
            self.motf_vie:setVisible(false)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECTLEVEL_DOWN)
    elseif name == "btn_home" then
        if self.m_status == 1 then
            return
        end
        --返回大厅
        self.m_status = 1
        self.m_view:setVisible(false)
        if self.motf_vie then
            self.motf_vie:setVisible(false)
        end
        self:setSpVisible(1)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECTLEVEL_UP)
    elseif name == "btn_frame" then
        --头像框关卡
        if self.m_status == 3 then
            return
        end
        self.m_status = 3
        self:setSpVisible(3)
        self.m_view:setVisible(false)
        self:createOther(1)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECTLEVEL_DOWN)
    elseif name == "btn_classic" then
        --其他关卡
        if self.m_status == 4 then
            return
        end
        self.m_status = 4
        self:setSpVisible(4)
        self.m_view:setVisible(false)
        self:createOther(2)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECTLEVEL_DOWN)
    end
end

function CollectTip:createOther(_flag)
    if not self.motf_vie then
        self.motf_vie = G_GetMgr(G_REF.CollectLevel):createColTbView()
        self.m_nodeTable:addChild(self.motf_vie)
    end
    self.motf_vie:updataList(_flag)
    self.motf_vie:setVisible(true)
end

function CollectTip:setSpVisible(_flag)
    for i,v in ipairs(self.m_spList) do
        if _flag == i then
            v:setVisible(true)
            self:addQiPao(i)
        else
            v:setVisible(false)
        end
    end
end

function CollectTip:addQiPao(_status)
    if self.m_hmpao and not tolua.isnull(self.m_hmpao) then
        self.m_hmpao:removeFromParent()
        self.m_hmpao = nil
    end
    self.m_hmpao = util_createView("views.CollectLevelCode.CollectQiPao",_status)
    if _status == 1 then
        self.m_homepao:addChild(self.m_hmpao)
    elseif _status == 2 then
        self.m_fvpao:addChild(self.m_hmpao)
    elseif _status == 3 then
        self.m_nodeframe:addChild(self.m_hmpao)
    elseif _status == 4 then
        self.m_nodeclassic:addChild(self.m_hmpao)
    end
    self.m_hmpao:showAction()
end

function CollectTip:setCollectVisible(_flag)
    self.m_status = 1
    self.m_view:setVisible(false)
    if self.motf_vie then
        self.motf_vie:setVisible(false)
    end
    for i,v in ipairs(self.m_spList) do
        if 1 == i then
            v:setVisible(true)
        else
            v:setVisible(false)
        end
    end
end

function CollectTip:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(sender, _index)
            self:setCollectVisible(true)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECTLEVEL_UP)
        end,
        ViewEventType.NOTIFY_COLLECTLEVEL_CLOSE
    )
end

return CollectTip