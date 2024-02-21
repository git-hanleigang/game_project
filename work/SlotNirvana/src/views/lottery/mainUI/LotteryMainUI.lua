--[[
Author: your name
Date: 2021-11-18 19:40:21
LastEditTime: 2021-11-18 19:50:49
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/mainUI/LotteryMainUI.lua
--]]
local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local LotteryMainUI = class("LotteryMainUI", BaseActivityMainLayer)

local Btn_Tag = {
    YOURS = 1, -- 自已的
    PAYTABLE = 2, -- paytable规则
    STATISTICS = 3, -- 开奖数据总结界面
    HISTORY = 4 -- 历史开奖界面
}

function LotteryMainUI:ctor(_callFunc,_tableIdx)
    LotteryMainUI.super.ctor(self)

    self.m_tagBtnList = {} -- tag btn
    self.m_tagSelSpList = {} -- tag选中的sp
    self.m_tagContentList = {} -- tag内的内容UI
    if _tableIdx then
        self.m_curTagType = _tableIdx
    else
        self.m_curTagType = Btn_Tag.YOURS
    end
    self.m_data = G_GetMgr(G_REF.Lottery):getData()
    self.m_callFunc = _callFunc

    self:setPauseSlotsEnabled(true)
    self:setKeyBackEnabled(true)
    self:setExtendData("LotteryMainUI")
    self:setLandscapeCsbName("Lottery/csd/MainUI/Lottery_MainUI_layer.csb")
    self:setBgm("Lottery/sounds/Lottery_bg_music_1.mp3")
    self:setShowBgOpacity(230)
end

-- 初始化节点
function LotteryMainUI:initCsbNodes()
    -- btn
    self.m_tagBtnList[Btn_Tag.YOURS] = self:findChild("btn_yours")
    self.m_tagBtnList[Btn_Tag.PAYTABLE] = self:findChild("btn_paytable")
    self.m_tagBtnList[Btn_Tag.STATISTICS] = self:findChild("btn_statistics")
    self.m_tagBtnList[Btn_Tag.HISTORY] = self:findChild("btn_history")

    -- 选中tag的sp
    self.m_tagSelSpList[Btn_Tag.YOURS] = self:findChild("sp_titel_Yours")
    self.m_tagSelSpList[Btn_Tag.PAYTABLE] = self:findChild("sp_titel_Paytable")
    self.m_tagSelSpList[Btn_Tag.STATISTICS] = self:findChild("sp_titel_Statisics")
    self.m_tagSelSpList[Btn_Tag.HISTORY] = self:findChild("sp_titel_History")

    -- content
    self.m_tagContentList[Btn_Tag.YOURS] = self:findChild("node_Yours")
    self.m_tagContentList[Btn_Tag.PAYTABLE] = self:findChild("node_Paytable")
    self.m_tagContentList[Btn_Tag.STATISTICS] = self:findChild("node_Statisics")
    self.m_tagContentList[Btn_Tag.HISTORY] = self:findChild("node_History")

    -- 时间
    self.m_lbTime = self:findChild("lb_time")
end

-- 初始化界面显示
function LotteryMainUI:initView()
    self:initContentUI()
    self:updateTagVisible()
end

-- 初始化内容
function LotteryMainUI:initContentUI()
    self:initYoursUI()
    self:initPaytableUI()
    self:initStatisicsUI()
    self:initHistoryUI()

    -- 乐透当期时间
    self:updateTimeUI()
    self.m_leftTimeScheduler = schedule(self, handler(self, self.updateTimeUI), 1)
end

-- 自己投注的记录
function LotteryMainUI:initYoursUI()
    local view = util_createView("views.lottery.mainUI.LotteryTagUIYours")
    self.m_tagContentList[Btn_Tag.YOURS]:addChild(view)
end
-- paytable
function LotteryMainUI:initPaytableUI()
    local view = util_createView("views.lottery.mainUI.LotteryTagUIPaytable")
    self.m_tagContentList[Btn_Tag.PAYTABLE]:addChild(view)
end
-- 预测号码
function LotteryMainUI:initStatisicsUI()
    local view = util_createView("views.lottery.mainUI.LotteryTagUIStatisics")
    self.m_tagContentList[Btn_Tag.STATISTICS]:addChild(view)
end
-- 开奖历史记录
function LotteryMainUI:initHistoryUI()
    local view = util_createView("views.lottery.mainUI.LotteryTagUIHistory")
    self.m_tagContentList[Btn_Tag.HISTORY]:addChild(view)
end

-- 更新按钮显隐
function LotteryMainUI:updateTagVisible()
    for tagName, tagType in pairs(Btn_Tag) do
        self.m_tagBtnList[tagType]:setTouchEnabled(tagType ~= self.m_curTagType)
        self.m_tagSelSpList[tagType]:setVisible(tagType == self.m_curTagType)
        self.m_tagContentList[tagType]:setVisible(tagType == self.m_curTagType)
    end
end

-- 更新乐透时间
function LotteryMainUI:updateTimeUI()
    local leftTimeStr, bOver = util_daysdemaining(self.m_data:getEndChooseTimeAt())
    if bOver then
        self.m_lbTime:setString("WAITING OPEN ...")
        self:clearScheduler()
        --self.m_lbTime:setVisible(false)
        return
    end

    self.m_lbTime:setString(leftTimeStr .. " LEFT")
end

function LotteryMainUI:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_shuoming" then
        G_GetMgr(G_REF.Lottery):showFAQView()
    elseif name == "btn_yours" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_curTagType = Btn_Tag.YOURS
        self:updateTagVisible()
    elseif name == "btn_paytable" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_curTagType = Btn_Tag.PAYTABLE
        self:updateTagVisible()
    elseif name == "btn_statistics" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_curTagType = Btn_Tag.STATISTICS
        self:updateTagVisible()
    elseif name == "btn_history" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_curTagType = Btn_Tag.HISTORY
        self:updateTagVisible()
    end
end

function LotteryMainUI:clearScheduler()
    if self.m_leftTimeScheduler then
        self:stopAction(self.m_leftTimeScheduler)
        self.m_leftTimeScheduler = nil
    end
end

-- 界面显示完毕播放音效
-- function LotteryMainUI:onShowedCallFunc()
--     LotteryMainUI.super.onShowedCallFunc(self)

--     -- 背景音乐
--     local bgMusicPath = self:getBgMusicPath()
--     if bgMusicPath and bgMusicPath ~= "" then
--         gLobalSoundManager:playBgMusic(bgMusicPath)
--         gLobalSoundManager:setLockBgMusic(true)
--         gLobalSoundManager:setLockBgVolume(true)
--     end
-- end

function LotteryMainUI:closeUI(...)
    -- 重置之前的背景音乐
    -- local bgMusicPath = self:getBgMusicPath()
    -- if bgMusicPath and bgMusicPath ~= "" then
    --     gLobalSoundManager:setLockBgMusic(false)
    --     gLobalSoundManager:setLockBgVolume(false)
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESET_BG_MUSIC)
    -- end
    local call = function()
        self.m_callFunc()
    end
    LotteryMainUI.super.closeUI(self, call)
end

return LotteryMainUI
