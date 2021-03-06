script_name('Admin Checker')
script_author('Fist')
script_version('1.0')
script_version_number(1)

local sampev           = require 'lib.samp.events'
local encoding         = require 'encoding'
local inicfg           = require 'inicfg'
local imgui            = require 'imgui'
local dlstatus         = require 'moonloader'.download_status
local updatesavaliable = false
encoding.default       = 'cp1251'
local u8               = encoding.UTF8
local prefix           = 'Checker'
local doRemove         = false
local admins           = {}
local admins_online    = {}

local ini = inicfg.load({
  settings = {
    shownotif    = true,
    showonscreen = false,
    posX         = 40,
    posY         = 460,
    color        = 0xFF0000,
    font         = 'Arial',
    startmsg     = true,
    sorttype     = 0,
    hideonscreen = true
  },
  color = {
    r = 255,
    g = 255,
    b = 255,
  },
}, 'admins')

function sampev.onPlayerQuit(id, _)
  for i, v in ipairs(admins_online) do
    if v['id'] == id then
      if ini.settings.shownotif then
        sampAddChatMessage(u8:decode('[Checker]: Администратор {2980b9}'..v['nick']..'{FFFFFF} покинул сервер.'), -1)
      end
      table.remove(admins_online, i)
      break
    end
  end
end

function sampev.onPlayerJoin(id, _, _, nick)
  for i, v in ipairs(admins) do
    if nick == v then
      if ini.settings.shownotif then
        sampAddChatMessage(u8:decode('[Checker]: Администратор {2980b9}'..nick..'{FFFFFF} зашел на сервер.'), -1)
      end
      table.insert(admins_online, {nick = nick, id = id})
      if ini.settings.sorttype == 0 then break end
      table.sort(admins_online, function(a, b)
        if ini.settings.sorttype == 1 then return a['id'] > b['id'] end
        if ini.settings.sorttype == 2 then return a['id'] < b['id'] end
        if ini.settings.sorttype == 3 then return a['nick'] > b['nick'] end
        if ini.settings.sorttype == 4 then return a['nick'] < b['nick'] end
      end)
      break
    end
  end
end

local main_window_state = imgui.ImBool(false)
local onscreen          = imgui.ImBool(ini.settings.showonscreen)
local hideonscreen      = imgui.ImBool(ini.settings.hideonscreen)
local startmsg          = imgui.ImBool(ini.settings.startmsg)
local shownotif         = imgui.ImBool(ini.settings.shownotif)
local sorttype          = imgui.ImInt(ini.settings.sorttype)
local tempX             = ini.settings.posX
local tempY             = ini.settings.posY
local posX              = imgui.ImInt(ini.settings.posX)
local posY              = imgui.ImInt(ini.settings.posY)
local pos               = imgui.ImVec2(0, 0)
local fontA             = imgui.ImBuffer(ini.settings.font, 256)

function alert(text)
  sampAddChatMessage(u8:decode('['..prefix..']: '..text), -1)
end

local r, g, b = imgui.ImColor(ini.color.r, ini.color.g, ini.color.b):GetFloat4()
local color = imgui.ImFloat3(r, g, b)
function imgui.OnDrawFrame()
  if main_window_state.v then
    imgui.Begin(thisScript().name..' v'..thisScript().version, main_window_state, imgui.WindowFlags.AlwaysAutoResize)
    if imgui.InputInt('X', posX) then
      ini.settings.posX = posX.v
      inicfg.save(ini, 'admins')
    end
    if imgui.InputInt('Y', posY) then
      ini.settings.posY = posY.v
      inicfg.save(ini, 'admins')
    end
    if imgui.Button('Указать мышкой где должен быть список') then
      alert('Нажмите {2980b9}ЛКМ{FFFFFF}, чтобы завершить. Нажмите {2980b9}ПКМ{FFFFFF}, чтобы отменить.')
      main_window_state.v = false
      doRemove = true
    end
    if imgui.InputText('Шрифт', fontA) then
      ini.settings.font = fontA.v
      font = renderCreateFont(ini.settings.font, 9, 5)
      inicfg.save(ini, 'admins')
    end
    if imgui.ColorEdit3('Цвет текста', color) then
      ini.color = {r = color.v[1] * 255, g = color.v[2] * 255, b = color.v[3] * 255, }
      ini.settings.color = join_argb(255, color.v[1] * 255, color.v[2] * 255, color.v[3] * 255)
      inicfg.save(ini, 'admins')
    end
    if imgui.CollapsingHeader('Способ сортировки') then
      if imgui.ListBox('', sorttype, {'Никак', 'По увеличению ID', 'По уменьшению ID', 'По алфавиту', 'По алфавиту наоборот'}, imgui.ImInt(5)) then
        ini.settings.sorttype = sorttype.v
        if sorttype.v ~= 0 then
          table.sort(admins_online, function(a, b)
            if sorttype.v == 1 then return a['id'] < b['id'] end
            if sorttype.v == 2 then return a['id'] > b['id'] end
            if sorttype.v == 3 then return a['nick'] < b['nick'] end
            if sorttype.v == 4 then return a['nick'] > b['nick'] end
          end)
        end
        inicfg.save(ini, 'admins')
      end
      imgui.Separator()
    end
    if imgui.Checkbox('Рендер на экране', onscreen) then
      ini.settings.showonscreen = onscreen.v
      inicfg.save(ini, 'admins')
    end
    if imgui.Checkbox('Прятать на скриншотах', hideonscreen) then
      ini.settings.hideonscreen = hideonscreen.v
      inicfg.save(ini, 'admins')
    end
    if imgui.Checkbox('Оповещения о входе/выходе администраторов', shownotif) then
      ini.settings.shownotif = shownotif.v
      inicfg.save(ini, 'admins')
    end
    if imgui.Checkbox('Стартовое сообщение', startmsg) then
      ini.settings.startmsg = startmsg.v
      inicfg.save(ini, 'admins')
    end
    if imgui.Button('Перезагрузить админов') then
        rebuildadmins()
    end
    if updatesavaliable then
      if imgui.Button('Скачать обновление') then
        update('https://raw.githubusercontent.com/Akionka/checker/master/checker.lua')
        main_window_state.v = false
      end
    else
      if imgui.Button('Проверить обновление') then
        checkupdates('https://raw.githubusercontent.com/MatthewahFist/Admin/master/version.json')
      end
    end
    imgui.End()
  end
end

function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(0) end

  checkupdates('https://raw.githubusercontent.com/MatthewahFist/Admin/master/version.json')
  rebuildadmins()

  if ini.settings.startmsg then
    sampAddChatMessage(u8:decode('[Checker]: Скрипт {00FF00}успешно{FFFFFF} загружен. Версия: {2980b9}'..thisScript().version..'{FFFFFF}.'), -1)
    sampAddChatMessage(u8:decode('[Checker]: Автор - {2980b9}Akionka{FFFFFF}. Выключить данное сообщение можно в {2980b9}/checker{FFFFFF}.'), -1)
    sampAddChatMessage(u8:decode('[Checker]: Кстати, чтобы посмотреть список администраторов он-лайн введи {2980b9}/admins{FFFFFF}.'), -1)
  end

  sampRegisterChatCommand('admins', function()
    if #admins_online == 0 then sampAddChatMessage(u8:decode('[Checker]: Администраторов он-лайн нет.'), -1) return true end
    sampAddChatMessage(u8:decode('[Checker]: В данный момент на сервере находится {2980b9}'..#admins_online..'{FFFFFF} администратор (-а, -ов):'), -1)
    for i, v in ipairs(admins_online) do
      sampAddChatMessage(u8:decode('[Checker]: {2980b9}'..v['nick']..' ['..v['id']..']{FFFFFF}.'), -1)
    end
    sampAddChatMessage(u8:decode('[Checker]: В данный момент на сервере находится {2980b9}'..#admins_online..'{FFFFFF} администратор (-а, -ов).'), -1)
  end)

  sampRegisterChatCommand('checker', function()
    imgui.SetNextWindowPos(imgui.ImVec2(200, 500), imgui.Cond.Always)
    main_window_state.v = not main_window_state.v
  end)

  font = renderCreateFont(ini.settings.font, 9, 5)
  while true do
    wait(0)
    if doRemove then
      showCursor(true, true)
      renderposX, renderposY = getCursorPos()
      renderFontDrawText(font, 'Admins Online ['..#admins_online..']:', renderposX, renderposY, bit.bor(ini.settings.color, 0xFF000000))
      renderposY = renderposY + 30
      for _, v in ipairs(admins_online) do
        renderFontDrawText(font, v['nick']..' ['..v['id']..']', renderposX, renderposY, bit.bor(ini.settings.color, 0xFF000000))
        renderposY = renderposY + 15
      end
      if isKeyJustPressed(0x02) then
        main_window_state.v = true
        showCursor(false, false)
        doRemove = false
        alert('Отменено.')
      end
      if isKeyJustPressed(0x01) then
        posX.v, posY.v = getCursorPos()
        main_window_state.v = true
        showCursor(false, false)
        doRemove = false
        alert('Новые координаты установлены.')
        ini.settings.posX = posX.v
        ini.settings.posY = posY.v
        inicfg.save(ini, 'admins')
      end
    end
    if not doRemove and ini.settings.showonscreen and (not isKeyDown(0x77) or not ini.settings.hideonscreen)  then
      local renderPosY = ini.settings.posY
      renderFontDrawText(font, 'Admins Online ['..#admins_online..']:', ini.settings.posX, ini.settings.posY, bit.bor(ini.settings.color, 0xFF000000))
      renderPosY = renderPosY + 30
      for _, v in ipairs(admins_online) do
        renderFontDrawText(font, v['nick']..' ['..v['id']..']', ini.settings.posX, renderPosY, bit.bor(ini.settings.color, 0xFF000000))
        renderPosY = renderPosY + 15
      end
    end
    imgui.Process = main_window_state.v
  end
end

function loadadmins()
  admins = {}
  if doesFileExist('moonloader/config/adminlist.txt') then
    for admin in io.lines('moonloader/config/adminlist.txt') do
      table.insert(admins, admin:match('(%S+)'))
    end
    print(u8:decode('Загрузка закончена. Загружено: '..#admins..' админов.'))
    io.open('moonloader/config/adminlist.txt', 'w'):write(table.concat(admins, '\n')):close()
  else
    print(u8:decode('Файла с админами в директории <moonloader/config/adminlist.txt> не обнаружено, создан автоматически'))
    io.close(io.open('moonloader/config/adminlist.txt', 'w'))
  end
end

function rebuildadmins()
  loadadmins()
  admins_online = {}
  for id = 0, 1000 do
    for i, v in ipairs(admins) do
      if sampIsPlayerConnected(id) then
        if sampGetPlayerNickname(id) == v then
          table.insert(admins_online, {nick = v, id = id})
        end
      end
    end
  end
  if sorttype.v ~= 0 then
    table.sort(admins_online, function(a, b)
      if sorttype.v == 1 then return a['id'] < b['id'] end
      if sorttype.v == 2 then return a['id'] > b['id'] end
      if sorttype.v == 3 then return a['nick'] < b['nick'] end
      if sorttype.v == 4 then return a['nick'] > b['nick'] end
    end)
  end
  sampAddChatMessage(u8:decode('[Checker]: Список админов онлайн перезагружен.'), -1)
end

function checkupdates(json)
  local fpath = os.getenv('TEMP')..'\\'..thisScript().name..'-version.json'
  if doesFileExist(fpath) then os.remove(fpath) end
  downloadUrlToFile(json, fpath, function(_, status, _, _)
    if status == dlstatus.STATUSEX_ENDDOWNLOAD then
      if doesFileExist(fpath) then
        local f = io.open(fpath, 'r')
        if f then
          local info = decodeJson(f:read('*a'))
          local updateversion = info.version_num
          f:close()
          os.remove(fpath)
          if updateversion > thisScript().version_num then
            updatesavaliable = true
            sampAddChatMessage(u8:decode('[Checker]: Найдено объявление. Текущая версия: {2980b9}'..thisScript().version..'{FFFFFF}, новая версия: {2980b9}'..info.version..'{FFFFFF}.'), -1)
            return true
          else
            updatesavaliable = false
            sampAddChatMessage(u8:decode('[Checker]: У вас установлена самая свежая версия скрипта.'), -1)
          end
        else
          updatesavaliable = false
          sampAddChatMessage(u8:decode('[Checker]: Что-то пошло не так, упс. Попробуйте позже.'), -1)
        end
      end
    end
  end)
end

function update(url)
  downloadUrlToFile(url, thisScript().path, function(_, status1, _, _)
    if status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
      sampAddChatMessage(u8:decode('[Checker]: Новая версия установлена! Чтобы скрипт обновился нужно либо перезайти в игру, либо ...'), -1)
      sampAddChatMessage(u8:decode('[Checker]: ... если у вас есть автоперезагрузка скриптов, то новая версия уже готова и снизу вы увидите приветственное сообщение.'), -1)
      thisScript():reload()
    end
  end)
end

function join_argb(a, r, g, b)
   local argb = b
   argb = bit.bor(argb, bit.lshift(g, 8))
   argb = bit.bor(argb, bit.lshift(r, 16))
   argb = bit.bor(argb, bit.lshift(a, 24))
   return argb
end