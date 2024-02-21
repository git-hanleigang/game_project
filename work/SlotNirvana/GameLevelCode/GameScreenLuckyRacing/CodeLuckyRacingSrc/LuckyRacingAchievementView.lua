---
--xcyy
--2018年5月23日
--LuckyRacingAchievementView.lua

local LuckyRacingAchievementView = class("LuckyRacingAchievementView",util_require("base.BaseView"))


function LuckyRacingAchievementView:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("LuckyRacing/ChengJiu.csb")
    self.m_choose = util_createAnimation("LuckyRacing_Huaxiang.csb")
    self:findChild("huaxiang"):addChild(self.m_choose)

    self:findChild("Panel_1"):setTouchEnabled(true)

    self.m_headItem = util_createView("CodeLuckyRacingSrc.LuckyRacingPlayerHead",{index = 1})
    self:findChild("touxiang"):addChild(self.m_headItem)
    
    --用户昵称
    self:findChild("kuang_0"):getChildByName("Text"):setString(globalData.userRunData.nickName)
    util_scaleCoinLabGameLayerFromBgWidth(self:findChild("kuang_0"):getChildByName("Text"), 192)
    --用户id
    self:findChild("kuang_1"):getChildByName("Text"):setString(globalData.userRunData.loginUserData.displayUid)

    local roomData = self.m_machine.m_roomData
end

function LuckyRacingAchievementView:showView()
    local playersInfo = self.m_machine.m_roomData:getRoomPlayersInfo()
    if #playersInfo == 0 then
        return
    end
    self:setVisible(true)
    self.m_isWaitting = true

    for index = 1,4 do
        self.m_choose:findChild("huaxiang_"..(index - 1)):setVisible(index == self.m_machine.m_curSelect + 1)
    end

    self.m_headItem.m_curIndex = self.m_machine.m_curSelect + 1
    self.m_headItem:refreshKuang()
    for index = 1,4 do
        local info = playersInfo[index]
        if info and info.udid == globalData.userRunData.userUdid then
            self.m_headItem:refreshData(info)
            --刷新头像
            self.m_headItem:refreshHead()
            break
        end
    end

    --成就记录
    local record = self.m_machine.m_roomData.m_teamData.room.extra.gameRecord

    --最大倍数
    self:findChild("kuang_2"):getChildByName("Font"):setString("X"..(record.biggestMultiplier or 0))
    --最高赢钱
    self:findChild("kuang_3"):getChildByName("Font"):setString(util_formatCoins((record.highestWin or 0),3))
    --累积获胜
    self:findChild("kuang_4"):getChildByName("Font"):setString((record.totalVictory) or 0)

    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_show_achievement.mp3")
    self:runCsbAction("start",false,function()
        self.m_isWaitting = false
        self:runCsbAction("idle",true)
    end)
end

function LuckyRacingAchievementView:hideView()
    if not self:isVisible() then
        return
    end
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_hide_achievement.mp3")
    self:runCsbAction("over",false,function()
        self:setVisible(false)
    end)
end

--默认按钮监听回调
function LuckyRacingAchievementView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "guanbi" then

        if self.m_isWaitting then
            return
        end
        self.m_isWaitting = true

        self:hideView()
    end
end

return LuckyRacingAchievementView