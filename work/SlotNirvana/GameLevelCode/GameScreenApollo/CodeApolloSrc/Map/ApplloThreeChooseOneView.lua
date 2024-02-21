
local ApplloThreeChooseOneView = class("ApplloThreeChooseOneView",util_require("base.BaseView"))

function ApplloThreeChooseOneView:initUI(data)
    local resourceFilename = "Apollo/BonusGameGame_2.csb"
    self:createCsbNode(resourceFilename)
    self.m_isCanClicked = false -- 是否可点击
    self.m_coinTab = {}--存金币对象的数组
    for i = 1,3 do
        --注册点击
        self:addClick(self:findChild("click"..i))
        --添加金币
        local jinbi = util_createAnimation("Apollo_map_xiaoguan_jinbi.csb")
        self:findChild("Apollo_jinbi_"..i):addChild(jinbi)
        table.insert(self.m_coinTab,jinbi)
        jinbi:playAction("idleframe",true)
        jinbi:findChild("coinNum"):setString(util_formatCoins(data.coinNum, 3))
    end

    self:runCsbAction("actionframe",false,function ()
        self.m_isCanClicked = true
        self:runCsbAction("idleframe",true)
    end)
end

function ApplloThreeChooseOneView:onEnter()
    ApplloThreeChooseOneView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:closeSelf()
    end,"ApplloThreeChooseOneView_closeSelf")
end

function ApplloThreeChooseOneView:onExit()
    ApplloThreeChooseOneView.super.onExit(self)
end

function ApplloThreeChooseOneView:clickFunc(sender)
    if self.m_isCanClicked == false then
        return
    end
    local name = sender:getName()
    local index = tonumber(string.match(name,"%d+"))
    self.m_isCanClicked = false
    self:openCoin(index)
    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_clickChooseOne.mp3")
end

--打开金币
function ApplloThreeChooseOneView:openCoin(index)
    local jinbi = self.m_coinTab[index]
    jinbi:playAction("actionframe",false,function ()
        local worldPos = jinbi:getParent():convertToWorldSpace(cc.p(jinbi:getPosition()))
        gLobalNoticManager:postNotification("GameScreenApolloMachine_chooseOneViewCollectCoin",{worldPos})
        jinbi:playAction("idleframe1",true)
    end)
end

function ApplloThreeChooseOneView:closeSelf()
    gLobalNoticManager:postNotification("ApolloMapMainView_closeSelfChooseOneEnd")
    self:removeFromParent()
end
return ApplloThreeChooseOneView