--[[
Author: cxc
Date: 2021-04-26 17:02:20
LastEditTime: 2021-05-13 11:47:00
LastEditors: Please set LastEditors
Description: 游戏本地推送的通知 配置  第一天从周日开始
FilePath: /SlotNirvana/src/data/localPush/LocalPushConfig.lua
--]]
local LocalPushConfig = {}
LocalPushConfig.FilterType = {
    -- text 文字推送
    -- 每日12点
    TEXT_12 = 1,
    -- 每日21点
    TEXT_21 = 2,
    -- 所有文字推送 
    TEXT = 3,

    -- img
    -- IMG_12 = 4,
    -- IMG_18 = 5,
    -- IMG_20 = 6,
    -- IMG_OTHER = 7,
    -- 离线图片推送
    IMG_OFFLINE = 8,
    -- 定点图片推送
    IMG = 9,

    -- other
    CASH_BONUS = 10,
    DAILY_BONUS = 11,
    NEWUSER_LOGIN = 12,
}

------------------------------- 纯文本推送配置 -------------------------------
--有奖励版本
local day12TextList  =
{
    {11,"Weekend BONUS!","Come and get your FREE BONUS in CASH TORNADO!!"},
    {12,"Take A Break!","Try some luck in CASH TORNADO with FREE COINS!!"},
    {13,"Lunch Time!","Treat yourself with some FREE COINS!"},
    {14,"Feel lucky?","Let's feel it in CASH TORNADO! Don't miss out on the FREE COINS!"},
    {15,"Almost Friday!","You are the awesome! FREE COINS for you in CASH TORNADO!"},
    {16,"Happy hours!","Enjoy your lunch and some FREE COINS in CASH TORNADO!"},
    {17,"Lazy Saturday","Enjoy your afternoon in a good mood with FREE COINS!!"},
}
local day21TextList =
{
    {21,"Sleep like a Baby!","Get ready for new challenges of the new week!"},
    {22,"Good night!","Don't want to say goodbye, but...see you tomorrow!"},
    {23,"Long night.","If you couldn't fall asleep, try CASH TORNADO!! "},
    {24,"Night falls.","Time for a break or... some FUN!!"},
    {25,"Exciting night!","Let's have some fun in CASH TORNADO!!"},
    {26,"Night Night!","Time for a good rest and get ready for weekend!"},
    {27,"Wonderful night!","Feel lucky? Try iin CASH TORNADO! It's your night."},
}
local textPush12Config = {}
local textPush21Config = {}
for i = 1, 7 do
    -- 每天12点的
    local info1 = day12TextList[i]
    table.insert(textPush12Config, {info1[1],info1[2],info1[3],info1[4],info1[5],i,12,0,true})
    -- 每天21点的
    local info2 = day21TextList[i]
    table.insert(textPush21Config, {info2[1],info2[2],info2[3],info2[4],info2[5],i,21,0})
end

------------------------------- 纯文本推送配置 -------------------------------


------------------------------- 带图片推送配置 -------------------------------
---周日为第一天  0 为当时段没有推送 1为有推送配置
local usePlan = "planB" -- 使用的推送计划
local pushPlan ={
    planA = {
        {0,0,0,0,0,1,1}, -- 09点
        {1,1,1,1,1,1,0}, -- 12点
        {0,1,1,1,1,1,1}, -- 13点
        {1,1,1,1,1,1,1}, -- 19点
        {1,1,1,1,1,1,1}, -- 21点
    },
    planB = {
        {0,0,0,0,0,1,1}, -- 09点
        {1,1,1,1,1,1,0}, -- 12点
        {0,0,0,0,0,1,1}, -- 13点
        {1,1,1,1,1,1,1}, -- 19点
        {1,1,1,1,1,1,1}, -- 21点
    },
    planC = {
        {0,0,0,0,0,1,1}, -- 09点
        {1,1,1,1,1,0,0}, -- 12点
        {0,0,0,0,0,0,0}, -- 13点
        {0,0,0,0,0,0,0}, -- 19点
        {1,1,1,1,1,1,1}, -- 21点
    }
}
----- 每天固定09点推送的
local imgPush09Info = {
    {},
    {},
    {},
    {},
    {},
    {"FREE 💰 INVITATION💌", "Enjoy a free 💰 breakfast with Mr. Cash💸"},
    {"🌞SATURDAY MORNING💰💰", "Don't get up early. Spin some funny!"},
}

-- 每天固定12点推送的
local imgPush12Info = {
    {"💖SATURDAY SPECIAL!💖", "⏰Don't let the free coins run away!💰"},
    {"😌CHILL DOWN AT NOON🍡", "🍻Beer,🎰games and food -- Perfect life!🎈"},
    {"🌻GIVE ME A HAND!✋", "🧡Help me take all the coins away.💰"},
    {"FREE 💰 INVITATION💌", "Enjoy a free 💰 breakfast with Mr. Cash💸"},
    {"THURSDAY 🎁GIVEAWAYS!", "Freebies waits no man! Claim 🆓"},
    {"🌞FRIDAY MORNING TREAT💰", "🎰Spinning like it never stops.💖"},
    {},
}

-- 每天固定13点推送的
local imgPush13Info = {
    {},
    {"🥰SOMEONE MISSING YOU", "🪙Because you forget to 💪claim free coins!"},
    {"😀HURRY UP! EVERYBODY'S HERE!😉", "Here's your 😍TEAM bonus! Have fun!🎁"},
    {"💰FORTUNE WHEEL'S HERE!🎡", "🎊Cash wheel gives you💰💰💰 Enjoy!"},
    {"🆕 GAME RELEASED!💰💰", "Want something special? Play 🆗"},
    {"🌹YOU GOT A DATE!✔", "🧡A date with Mr. Cash😎"},
    {"🔔DING DONG! YOUR🎁", "Open it!🌞It's your free coins!💰"},
}

-- 每天固定19点推送的
local imgPush19Info = {
    {"🎊YOU ARE THE CHAMPION🥇️", "🏃RUSH FOR LEAGUES POINTS!🏁"},
    {"FREE COINS SEA🌊", "Win big like a King/Queen of the ocean."},
    {"🤫SHHHH!💰💰💰", "🚀Take all coins away when no one cares.🎀"},
    {"🎉NEW CHIPS NEW SETS!🌈", "⛴Start a new journey for new chips!"},
    {"FREE COINS SEA🌊", "Win big like a King/Queen of the ocean."},
    {"🌟FRIDAY PARTY NIGHT🌜", "🎉Party time: rock & spin &💰💰💰"},
    {"🎰GOOD GAMES ON🕹️", "Let the game show kick off your Saturday🌃"},
}

-- 每天固定21点推送的
local imgPush21Info = {
    {"🚚 Beep Beep!", "💰You have a coin delivery!🚚 "},
    {"😴GOOD RELAX IDEA💡", "☪Spin a while before sleeping!🛌🏾"},
    {"🎈WOOHOO! SUPRRISE!🎁", "💰You have full bags of coins!🌈"},
    {"💰💰💰 PARTY ROCKS!🎶", "🎁Today a mistery gift awaits!"},
    {"⭐THURSDAY OPEN CHEST🎁", "💰💰 in TEAM treasure chest!🌠"},
    {"🌟HAVE A BLAST NOW!🎰", "🧲Catch the coins and they are all yours!🎁"},
    {"💰MISSION POSSIBLE!🎯", "🎈Always get coins from Daily Mission!🚀"},
}

local imgPush09Config = {}
local imgPush12Config = {}
local imgPush13Config = {}
local imgPush19Config = {}
local imgPush21Config = {}
for i=1, 7 do
    -- 每日09点的推送
    local plan_09_Today = pushPlan[usePlan][1][i]
    if plan_09_Today > 0 then
        local info_09 = imgPush09Info[i]
        table.insert(imgPush09Config, {tonumber("1"..i.."09"), info_09[1], info_09[2], nil, nil, i, 9, 0, true})
    end

    -- 每日12点的推送
    local plan_12_Today = pushPlan[usePlan][2][i]
    if plan_12_Today > 0 then
        local info_12 = imgPush12Info[i]
        table.insert(imgPush12Config, {tonumber("1"..i.."12"), info_12[1], info_12[2], nil, nil, i, 12, 0, true})
    end

    -- 每日13点的推送
    local plan_13_Today = pushPlan[usePlan][3][i]
    if plan_13_Today > 0 then
        local info_13 = imgPush13Info[i]
        table.insert(imgPush13Config, {tonumber("1"..i.."13"), info_13[1], info_13[2], nil, nil, i, 13, 0, true})
    end

    -- 每日19点的推送
    local plan_19_Today = pushPlan[usePlan][4][i]
    if plan_19_Today > 0 then
        local info_19 = imgPush19Info[i]
        table.insert(imgPush19Config, {tonumber("1"..i.."17"), info_19[1], info_19[2], nil, nil, i, 17, 0, true})
    end

    -- 每日21点的推送
    local plan_21_Today = pushPlan[usePlan][5][i]
    if plan_21_Today > 0 then
        local info_21 = imgPush21Info[i]
        table.insert(imgPush21Config, {tonumber("1"..i.."21"), info_21[1], info_21[2], nil, nil, i, 21, 0, true})
    end
end

-- 玩家离线间隔时间推送
local imgPushOffLineConfig = 
{
    -- 玩家离线超过6小时、12小时、24小时
    {3000,"💗We miss your spins!💗","Come back and discover surprise rewards we have prepared for you!😍","offlinnew1_1.jpg","offlinnew1_2.jpg",21600},
    {3001,"Your lucky moment awaits!🔮","✨Don't let the Slots magic fade away! It's time to reclaim your place among the spinning legends!","offlinnew2_1.jpg","offlinnew2_2.jpg",43200},
    {3002,"A whole day without the thrill of spinning?🎰","A day off the reels is a day wasted! 🔥It's time to break the silence! Don't miss out on the chance to unlock extraordinary wins and bonuses!🥇","offlinnew3_1.jpg","offlinnew3_2.jpg",86400},
}
 
------------------------------- 带图片推送配置 -------------------------------

------------------------------- 其他 推送配置 -------------------------------
local cashBonusConfig = {"Cash Bonus Ready！","Keep logging in to get more rewards! Don't miss out on any chance!"}
local dailyBonusConfig = {"DAILY BONUS","Collect your FREE BONUS NOW!! Get closer to MEGA SPIN!! Don't miss it!!"}
local newuserLoginPushConfig = {
    -- 如有要从400加的 从420开始...预留20个位置给上层
    {400,"It's time to reignite the reels!🔥","🎉Get back in the action and witness the sheer brilliance of our latest Slots games. Brace yourself for mind-blowing bonuses!🎁","img_login_small.jpeg","img_login_big.jpeg"},
    {401,"🎁An explosion of rewards are piling up!","💥Log in now and experience a BOOMing adventure with jaw-dropping bonuses and explosive prizes!🎉","img_rewards_small.jpeg","img_rewards_big.jpeg"},
}
------------------------------- 其他 推送配置 -------------------------------

function LocalPushConfig:getConfig(_type)
    if _type == LocalPushConfig.FilterType.TEXT_12 then
        return textPush12Config 
    elseif _type == LocalPushConfig.FilterType.TEXT_21 then
        return textPush21Config 
    elseif _type == LocalPushConfig.FilterType.TEXT then
        return self:joinTable(textPush12Config, textPush21Config)
    elseif _type == LocalPushConfig.FilterType.IMG then
        return self:joinTable(imgPush09Config,imgPush12Config, imgPush13Config, imgPush19Config, imgPush21Config)
    elseif _type == LocalPushConfig.FilterType.IMG_OFFLINE then
        return imgPushOffLineConfig
    elseif _type == LocalPushConfig.FilterType.CASH_BONUS then
        return cashBonusConfig
    elseif _type == LocalPushConfig.FilterType.DAILY_BONUS then
        return dailyBonusConfig
    elseif _type == LocalPushConfig.FilterType.NEWUSER_LOGIN then
        return newuserLoginPushConfig
    end 
    return {}
end

function LocalPushConfig:joinTable(...)
    local tb = {}

    for _, atb in pairs{...} do
        for k,v in pairs(atb) do
            table.insert(tb,v)
        end
    end

    return tb
end

return LocalPushConfig