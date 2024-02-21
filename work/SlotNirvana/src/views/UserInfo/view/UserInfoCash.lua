local UserInfoCash = class("UserInfoCash", BaseLayer)


function UserInfoCash:ctor()
    UserInfoCash.super.ctor(self)
    self:setExtendData("UserInfoCash")
    self:setLandscapeCsbName("Activity/csd/Information_CashDice/Iformation_CashDice_zong/Information_CashDice_Zong.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:setShowActionEnabled(false)
    self:setMaskEnabled(false)
end

function UserInfoCash:initView()
    self:runCsbAction(
        "idle",
        true,
        function()
        end,
        60
    )
    self:updataItem()
	--self:updataTabview()
    self:updataLayer()
    self:updateMiniGameBtnState()
end

function UserInfoCash:updataLayer()
    self.page_layer = self:findChild("page_layer")
    local btn_layer = self:findChild("laybtn")
    self:addClick(btn_layer)
    local size = self.page_layer:getContentSize()
    local page_node,node_act = util_csbCreate("Activity/csd/Information_FramePartII/FramePartII_Frame_Entrance.csb")
    page_node:setPosition(size.width/2,size.height/2)
    self.page_layer:addChild(page_node)
    util_csbPlayForKey( node_act ,"idle",true,nil ,60 )
    print("zuixin")
end

-- 小游戏入口按钮 state
function UserInfoCash:updateMiniGameBtnState()
    -- 新手期集卡 不可玩 头像框小游戏
    local bCardNovice = CardSysManager:isNovice()
    self:setButtonLabelDisEnabled("btn_roll", not bCardNovice)
end

function UserInfoCash:updataTabview()
    local size = cc.size(620,500)
    local param = {
        tableSize = size,
        parentPanel = self:findChild("root"),
        directionType = 2
    }
    self.m_tableView = util_require("views.UserInfo.view.UserInfoHeadTableView").new(param)
    self:findChild("root"):addChild(self.m_tableView)
    self.m_tableView:setPosition(390,85)
    self.m_tableView:reload(self.ManGer:getData():getCashData(),4)
end

function UserInfoCash:initCsbNodes()
    self.desc = self:findChild("txt_desc")
    self.roll_num = self:findChild("txt_desc2")
    self.reward_name = self:findChild("txt_desc3")
    self.node_reward = self:findChild("node_reward")
    self.btn_roll = self:findChild("btn_roll")
end

function UserInfoCash:updataItem()
    local data = self.ManGer:getData():getCashData()
    local miniGameData = G_GetMgr(G_REF.AvatarFrame):getData():getMiniGameData()
    local count = 0
    if miniGameData then
        count = miniGameData:getPropsNum()
    end
    local str = count.."    ROLL NOW"
    if count >= 10 and count<100 then
        str = count.."  ROLL NOW"
    elseif count >= 100 then
        str = count.."  ROLL NOW"
    end
    
    self:setButtonLabelContent("btn_roll", str)
end


function UserInfoCash:registerListener()
    gLobalNoticManager:addObserver(self,function(self, itemData)
        self:updataItem()
    end,ViewEventType.NOTIFY_USER_GAME_PLAY)
end

function UserInfoCash:onEnter()
    self:registerListener()
end



function UserInfoCash:clickStartFunc(sender)
end

function UserInfoCash:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_roll" then
        G_GetMgr(G_REF.AvatarGame):showMainLayer()
    elseif name == "button_entry" or name == "laybtn" then
        self.ManGer:showAchievements()
    end
end

return UserInfoCash