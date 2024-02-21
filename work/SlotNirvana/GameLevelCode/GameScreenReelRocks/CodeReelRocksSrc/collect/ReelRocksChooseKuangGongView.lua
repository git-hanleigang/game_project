---
--xcyy
--2018年5月23日
--ReelRocksChooseKuangGongView.lua 比赛选择界面

local ReelRocksChooseKuangGongView = class("ReelRocksChooseKuangGongView", util_require("base.BaseView"))
ReelRocksChooseKuangGongView.m_ClickIndex = 1
ReelRocksChooseKuangGongView.m_spinDataResult = {}

function ReelRocksChooseKuangGongView:initUI(data)
    self:createCsbNode("ReelRocks/ReelRocks_bisaiStart.csb")
    self:setClickVisible(true)
    self:addClick(self:findChild("Click_lan"))
    self:addClick(self:findChild("Click_hong"))
    self:addClick(self:findChild("Click__lv"))

    self.viewBg = util_createView("CodeReelRocksSrc.ReelRocksCollectActView", "ReelRocks/GameScreenReelRocksBg") --背景
    self:findChild("Node_bg"):addChild(self.viewBg)
    self.viewBg:runCsbAction("idle3", true)

    self.renQun = util_createView("CodeReelRocksSrc.ReelRocksCollectActView", "ReelRocks_bisai_renqun") --人群
    self:findChild("renqun"):addChild(self.renQun)
    self.renQun:runCsbAction("idle1", true)

    self:initKuangGong()
    self:initViewTop(data)
    self.m_Click = false
    self.m_ClickIndex = 1
    self.m_isStart_Over_Action = true
    self.isClick = false

    performWithDelay(
        self,
        function()
            -- gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_ChooseShow.mp3")
        end,
        0.3
    )
end

function ReelRocksChooseKuangGongView:initViewTop(data)
    local rankMultiplies = data.rankMultiplies
    local priceKuang = util_createView("CodeReelRocksSrc.ReelRocksCollectActView", "ReelRocks_bisai_pricekuang")
    self:findChild("bisai_pricekuang"):addChild(priceKuang)
    priceKuang:changeNum(util_formatCoins(data.collectAvgBet, 3))

    local beiShu_1 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView", "ReelRocks_bisai_beishukuang_1")
    self:findChild("bisai_beishukuang_1"):addChild(beiShu_1)
    beiShu_1:runCsbAction("idle", true)
    beiShu_1:changeNum(rankMultiplies[1] .. "X") --改变倍数

    local beiShu_2 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView", "ReelRocks_bisai_beishukuang_2")
    self:findChild("bisai_beishukuang_2"):addChild(beiShu_2)
    beiShu_2:runCsbAction("idle", true)
    beiShu_2:changeNum(rankMultiplies[2] .. "X")

    local beiShu_3 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView", "ReelRocks_bisai_beishukuang_3")
    self:findChild("bisai_beishukuang_3"):addChild(beiShu_3)
    beiShu_3:runCsbAction("idle", true)
    beiShu_3:changeNum(rankMultiplies[3] .. "X")
end

--绿红蓝矿车分别为123
function ReelRocksChooseKuangGongView:initKuangGong()
    self.kuangGong_1 = util_spineCreate("Socre_ReelRocks_5", true, true)
    self.biaoJi_1 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView", "ReelRock_biaoji")
    self.kuangGong_1:addChild(self.biaoJi_1)
    self.biaoJi_1:setPosition(cc.p(0, 322))
    self.biaoJi_1:setVisible(false)
    self:findChild("Node_bisai_che_lv"):addChild(self.kuangGong_1)
    self.kuangGong_1:setPosition(0, 0)
    util_spinePlay(self.kuangGong_1, "idleframe3", true)
    self.kuangGong_2 = util_spineCreate("Socre_ReelRocks_8", true, true)
    self.biaoJi_2 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView", "ReelRock_biaoji")
    self.kuangGong_2:addChild(self.biaoJi_2)
    self.biaoJi_2:setPosition(cc.p(0, 322))
    self.biaoJi_2:setVisible(false)
    self:findChild("Node_bisai_che_hong"):addChild(self.kuangGong_2)
    self.kuangGong_2:setPosition(0, 0)
    util_spinePlay(self.kuangGong_2, "idleframe3", true)
    self.kuangGong_3 = util_spineCreate("Socre_ReelRocks_6", true, true)
    self.biaoJi_3 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView", "ReelRock_biaoji")
    self.kuangGong_3:addChild(self.biaoJi_3)
    self.biaoJi_3:setPosition(cc.p(0, 322))
    self.biaoJi_3:setVisible(false)
    self:findChild("Node_bisai_che_lan"):addChild(self.kuangGong_3)
    self.kuangGong_3:setPosition(0, 0)
    util_spinePlay(self.kuangGong_3, "idleframe3", true)
end

function ReelRocksChooseKuangGongView:setRunAct()
    util_spinePlay(self.kuangGong_1, "idleframe4", true)
    util_spinePlay(self.kuangGong_2, "idleframe4", true)
    util_spinePlay(self.kuangGong_3, "idleframe4", true)
end

function ReelRocksChooseKuangGongView:onEnter()
end

function ReelRocksChooseKuangGongView:onExit()
end

function ReelRocksChooseKuangGongView:checkAllBtnClickStates()
    local notClick = false

    if self.m_action == self.ACTION_SEND then
        notClick = true
    end

    if self.m_Click then
        notClick = true
    end

    if self.m_isStart_Over_Action then
        notClick = true
    end

    return notClick
end

--默认按钮监听回调
function ReelRocksChooseKuangGongView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    self.m_Click = true
    if self.isClick then
        if name == "Click__lv" then
            self.m_ClickIndex = 1
            gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_chooseCar.mp3")
            self:setBiaoJiIdle(self.m_ClickIndex)
            performWithDelay(
                self,
                function()
                    self:closeUi()
                end,
                1
            )
        elseif name == "Click_hong" then
            self.m_ClickIndex = 2
            gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_chooseCar.mp3")
            self:setBiaoJiIdle(self.m_ClickIndex)
            performWithDelay(
                self,
                function()
                    self:closeUi()
                end,
                1
            )
        elseif name == "Click_lan" then
            self.m_ClickIndex = 3
            gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_chooseCar.mp3")
            self:setBiaoJiIdle(self.m_ClickIndex)
            performWithDelay(
                self,
                function()
                    self:closeUi()
                end,
                1
            )
        end
    end
end

function ReelRocksChooseKuangGongView:setClick(isClick)
    self.isClick = isClick
end

--将标记、选中效果、压黑写到了一起
function ReelRocksChooseKuangGongView:setBiaoJiIdle(index)
    self:stopAllActions()
    self:runCsbAction("idle2", false)
    self.isClick = false
    if index == 1 then
        self:setClickVisible(false)
        self.biaoJi_1:setVisible(true)
        self.biaoJi_1:runCsbAction("idle", true)
        util_spinePlay(self.kuangGong_1, "actionframe3", false)
        util_spineEndCallFunc(
            self.kuangGong_1,
            "actionframe3",
            function()
                util_spinePlay(self.kuangGong_1, "idleframe4", true)
            end
        )
        util_spinePlay(self.kuangGong_2, "actionframe4", false)
        util_spinePlay(self.kuangGong_3, "actionframe4", false)
    elseif index == 2 then
        self:setClickVisible(false)
        self.biaoJi_2:setVisible(true)
        self.biaoJi_2:runCsbAction("idle", true)
        util_spinePlay(self.kuangGong_2, "actionframe3", false)
        util_spineEndCallFunc(
            self.kuangGong_2,
            "actionframe3",
            function()
                util_spinePlay(self.kuangGong_2, "idleframe4", true)
            end
        )
        util_spinePlay(self.kuangGong_1, "actionframe4", false)
        util_spinePlay(self.kuangGong_3, "actionframe4", false)
    elseif index == 3 then
        self:setClickVisible(false)
        self.biaoJi_3:setVisible(true)
        self.biaoJi_3:runCsbAction("idle", true)
        util_spinePlay(self.kuangGong_3, "actionframe3", false)
        util_spineEndCallFunc(
            self.kuangGong_3,
            "actionframe3",
            function()
                util_spinePlay(self.kuangGong_3, "idleframe4", true)
            end
        )
        util_spinePlay(self.kuangGong_1, "actionframe4", false)
        util_spinePlay(self.kuangGong_2, "actionframe4", false)
    end
end

function ReelRocksChooseKuangGongView:getClickIndex()
    return self.m_ClickIndex
end

function ReelRocksChooseKuangGongView:setEndCall(func)
    self.m_bonusEndCall = func
end

function ReelRocksChooseKuangGongView:setClickVisible(isVisible)
    if isVisible then
        self:findChild("Click_lan"):setVisible(true)
        self:findChild("Click_hong"):setVisible(true)
        self:findChild("Click__lv"):setVisible(true)
    else
        self:findChild("Click_lan"):setVisible(false)
        self:findChild("Click_hong"):setVisible(false)
        self:findChild("Click__lv"):setVisible(false)
    end
end

function ReelRocksChooseKuangGongView:closeUi(func)
    if self.m_bonusEndCall then
        -- self:runCsbAction("over",false,function(  )
        self.m_bonusEndCall()
    -- end)
    end
end

return ReelRocksChooseKuangGongView
