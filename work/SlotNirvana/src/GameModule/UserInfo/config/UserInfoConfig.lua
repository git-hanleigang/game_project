--[[
    用户信息置文件
]]
local UserInfoConfig = {}
local SensitiveWordParser = require("utils.sensitive.SensitiveWordParser")

UserInfoConfig.ItmeTag = {
    ITEM_ME = 1,
    PERSON = 2,
    SOLT = 3,
    BG = 4
}

UserInfoConfig.BtnPath = {
    "Information_page_desc7.png",
    "Information_page_desc8.png",
    "Information_page_desc5.png",
    "Information_page_desc6.png",
    "Information_page_desc3.png",
    "Information_page_desc4.png",
    "Information_page_desc1.png",
    "Information_page_desc2.png",
}

UserInfoConfig.VipLevle = {
    "BRONZE",
    "SILVER",
    "GOLD",
    "PLATINUM",
    "DIAMOND",
    "ROYAL DIAMOND",
    "BLACK"
}

UserInfoConfig.imagePath1 = {
    "Information_page1.png",
    "Information_desc1.png",
    "Information_page2.png",
    "Information_desc4.png",
}

UserInfoConfig.imagePath2 = {
    "Information_page2.png",
    "Information_desc2.png",
    "Information_page1.png",
    "Information_desc3.png",
}

UserInfoConfig.SessionIconName = {
    "ROOKIE",
    "EXPERT I",
    "EXPERT II",
    "PRO I",
    "PRO II",
    "PRO III",
    "MASTER I",
    "MASTER II",
    "MASTER III",
    "LEGEND"
}

UserInfoConfig.ViewEventType = {
    NOTIFY_USERINFO_MODIFY_SUCC = "NOTIFY_USERINFO_MODIFY_SUCC",
    --修改信息成功
    NOTIFY_USERINFO_MODIFY_FAIL = "NOTIFY_USERINFO_MODIFY_FAIL",
    --修改失败非法字
    NOTIFY_USERINFO_CLICK_HEAD = "NOTIFY_USERINFO_CLICK_HEAD",
    OBTAIN_BIND_EMAIL_REWARD = "OBTAIN_BIND_EMAIL_REWARD", --获得第一次绑定邮箱后的奖励
    RECIVE_REMOTE_BAG_INFO = "RECIVE_REMOTE_BAG_INFO", --获取到 背包信息
    BAG_ITEM_CLICKED = "BAG_ITEM_CLICKED", -- 选中某一道具 主panel refershUI
    BAG_ITEM_UNCLICKED = "BAG_ITEM_UNCLICKED", -- 取消选中的 某一道具
    SHOW_BAG_UI = "SHOW_BAG_UI", -- 显示背包UI（新手引导事件）
    SAVE_NICK_NAME = "SAVE_NICK_NAME", -- 保存名字

    MAIN_CLOSE = "MAIN_CLOSE",
    AVR_ITEM_CLICK = "AVR_ITEM_CLICK",
    FRAME_ITEM_CLICK = "FRAME_ITEM_CLICK",
    MAIN_IN = "MAIN_IN",
    MAIN_HASTIORY = "MAIN_HASTIORY",
    FRAME_LIKE_SELECT = "FRAME_LIKE_SELECT",
    FRAME_AVMENT_LEVEL = "FRAME_AVMENT_LEVEL",
    FRAME_AVMENT_FRAME = "FRAME_AVMENT_FRAME",
    CASH_AVMENT_ANIFRAME = "CASH_AVMENT_ANIFRAME",
    CASH_AVMENT_ANILEVEL = "CASH_AVMENT_ANILEVEL",
    FRAME_AVMENT_ANILEVEL = "FRAME_AVMENT_ANILEVEL",
}

-- 活动配置
UserInfoConfig.ActivityMainViewMap = {
    -- downloadName = activityName
    Activity_QuestNewUser = "QuestNewUserMainView",
    Activity_Quest = "QuestMainView",
    Activity_Bingo = "BingoSelectUI",
    DefenderGameUI = "DefenderGameUI",
    FindItemPopupView = "FindItemPopupView",
    Activity_DinnerLand = "DinnerLandGameUI",
    Activity_RichMan = "RichManMain",
    Activity_Blast = "BlastMainUI",
    Activity_Word = "WordMainUI",
    Activity_LuckyChipsDraw = "LuckyChipsDrawMainUI",
    Activity_CoinPusher = "CoinPusherSelectUI",
    Activity_Redeocr = "RedecorMainUI"
}

--音乐音效
UserInfoConfig.SoundPath = {
    BGM = "Activity/sound/fg_bgm.mp3", --背景音
    OPEN = "Activity/sound/fg_open.mp3",  --翻书打开
    SLIDE = "Activity/sound/fg_slide.mp3",  --翻页
    BACKSLIDE = "Activity/sound/fg_backslide.mp3",  --往回翻页
    ENTER = "Activity/sound/fg_enter.mp3",  --进入内容页
    FRESH = "Activity/sound/fg_fresh.mp3",  --头像框刷新
    CLOSE = "Activity/sound/fg_close.mp3"  --关闭
}
-- 改变名字后 7天后才能改
UserInfoConfig.LockChangeNameTime = 7 * 24 * 3600
--
--[[
    输入空使用EditBox
    params: {
        textFiled: textFiled控件
        bgImgName: editBox需要的图片资源path
        handlerFunc: editbox的事件回调
    }
]]
UserInfoConfig.convertTextFiledToEditBox = function(textFiled, bgImgName, handlerFunc, inputModel)
    return util_convertTextFiledToEditBox(textFiled, bgImgName, handlerFunc, inputModel)
end

UserInfoConfig.getSensitiveStr = function(_str)
    return SensitiveWordParser:getString(_str)
end

--- 获取字符宽度（中文算3个字符）
UserInfoConfig.getStrUtf8Len = function(input)
    local len = string.len(input)
    local left = len
    local cnt = 0
    local arr = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local addNum = 1
        local tmp = string.byte(input, -left)
        local i = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                if i >= 4 then
                    addNum = 2
                end
                break
            end
            i = i - 1
        end
        cnt = cnt + addNum
    end
    return cnt
end

-- 或去格式化的 时间str
UserInfoConfig.getTimeStr = function(_time)
    _time = tonumber(_time) or 0

    local daySec = 24 * 60 * 60
    local day = _time / daySec
    if day > 1 then
        return math.floor(day) .. " DAYS LEFT", day > 1.1
    end

    return util_count_down_str(_time)
end

UserInfoConfig.setButtonEnble = function(btn,enble,label,attr)
    btn:setEnabled(enble)
    if enble then
        if attr.shadowColor and attr.shadowOffset then
            label:enableShadow(attr.shadowColor, attr.shadowOffset)
        end
        if attr.outlineColor and attr.outlineSize then
            label:enableOutline(attr.outlineColor, attr.outlineSize)
        end
        label:setTextColor(attr.color)
    else
        label:disableEffect()
        label:enableOutline(cc.c4b(63, 63, 63, 255), attr.outlineSize)
        label:setTextColor(cc.c4b(255, 255, 255, 255))
    end
end

-- 背包UI 显示几列
UserInfoConfig.COL_NUM = 4 -- 4列

return UserInfoConfig
