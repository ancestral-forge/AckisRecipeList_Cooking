local _, addon = ...
addon.group, addon.title = "Cooking Triage", "Cooking Triage Verification"
addon.route = {}
local route = addon.route
local function copy(t) local r = {}; for k,v in pairs(t) do r[k] = v end; return r end
local function note(text) route[#route + 1] = {kind = "note", text = text} end
local function travel(zone, mapID, x, y, title, text, applies)
    route[#route + 1] = {kind = "travel", zone = zone, mapID = mapID, x = x, y = y, title = title, text = text, applies = applies}
end
local function visit(id, text)
    local point = copy(assert(addon.nodes[id], "Missing census NPC " .. id))
    point.kind, point.text, point.caseIDs = "verify", text or "Открой полное меню. Результаты: /ctriage. Галочка Guidelime отмечает посещение, а не совпадение рецептов.", {}
    local confident, uncertain, rogueOnly = 0, 0, true
    for _, case in ipairs(addon.catalog) do
        if case.sourceID == id and (case.kind == "vendor" or case.kind == "trainer" or case.kind == "quest" or case.kind == "container" or case.kind == "drop") then
            point.caseIDs[#point.caseIDs + 1] = case.id
            if case.confidence == "confident" then confident = confident + 1 else uncertain = uncertain + 1 end
            if case.class ~= "ROGUE" then rogueOnly = false end
        end
    end
    if rogueOnly then point.applies = "Rogue" end
    point.text = ("*Уверенная группа: %d; сомнительная: %d.* "):format(confident, uncertain) .. point.text
    if point.approximate then point.text = point.text .. " Координаты — стоянка подвижного каравана; не найденный NPC не означает отсутствия рецепта." end
    route[#route + 1] = point
end
local function visits(...) for _, id in ipairs({...}) do visit(id) end end
local function fly(id, destination)
    local point = copy(assert(addon.flightNodes[id], "Missing flight NPC " .. id))
    point.kind, point.flight, point.text = "flight", destination, "Лети в " .. destination .. "."
    route[#route + 1] = point
end

note("*Полная перепроверка источников Cooking.* Альянс, все грифоны открыты, включая острова дренеев. Начало — Шаттрат. /ctriage start начинает новый пробег и фиксирует уверенность/ожидания. Уже изученные рецепты тоже проверяем. Старые результаты сохраняются.")
note("*Что считается результатом.* Наличие в меню записывается автоматически. Отсутствие подтверждай в /ctriage только после проверки полного меню. Нет запаса, фильтры, репутация, завершённый квест, отсутствующий NPC — 'Позже', не опровержение. /ctriage report — статистика двух исходных групп; /ctriage finish — завершить и сохранить отчёт.")
travel("Shattrath City",1955,75.23,33.88,"Shaarubo — камень в Шаттрат","Привяжи Hearthstone у Shaarubo. Привязку сохраняй до конца Старого мира.")
visit(19186,"Полное меню Kylene, включая used/unavailable. Особое внимание Stewed Trout (320/325), Fisherman's Feast, Hot Buttered Trout и обычным низкоуровневым рецептам.")
visits(19185,19195)
visit(24393,"Проверь Cooking daily. Рецепты из Barrel of Fish / Crate of Meat подтверждает фактическая добыча, а не показанный контейнер. Неоткрытые награды остаются отложенными.")
travel("Shattrath City",1955,54,44,"Портал в Экзодар","На Terrace of Light используй портал The Exodar. Отметь после прибытия.")
visits(16718,16719)
fly(17555,"Blood Watch"); visit(18427); fly(17554,"The Exodar")
visit(17110,"После возвращения выйди из Экзодара в Azuremyst Isle к Azure Watch. Проверь квестовый рецепт Acteon.")
visit(17246)
travel("Azuremyst Isle",1943,20.4,54.1,"Корабль в Auberdine","Иди на западный причал Azuremyst и садись на корабль в Auberdine. Галочка после высадки.")
fly(3841,"Rut'theran Village"); visit(10118)
travel("Teldrassil",1438,55.9,89.7,"Портал в Дарнас","Пройди через розовый портал в Darnassus; отметь после прибытия.")
visits(4223,4210)
visit(6286,"В Dolanaar проверь и trainer-меню Zarrin, и награду Recipe of the Kaldorei, quest 4161.")
visit(4265)
travel("Darnassus",1457,30,41.5,"Назад в Rut'theran","Вернись в Дарнас и пройди розовым порталом к грифону Rut'theran.")
fly(3838,"Auberdine"); visits(3702,4200,4307)
fly(3841,"Astranaar"); visit(3960)
fly(4267,"Everlook"); visit(11187)
fly(11138,"Talonbranch Glade"); visit(2803)
fly(12578,"Nijel's Point"); visits(8150,12245,12246)
visit(14354,"По дороге на юг войди в Feralas. Точка — вход в Dire Maul East; Pusillin внутри. Нужен реальный loot Runn Tum Tuber Surprise. Если инстанс сейчас не проходишь, отметь 'Позже' и продолжай.")
travel("Feralas",1444,43,42.8,"Паром в Feathermoon","Доберись до берегового причала и переправься в Feathermoon Stronghold. Обратно улетим грифоном.")
visit(7947); fly(8019,"Cenarion Hold"); visit(15174)
fly(15177,"Gadgetzan"); visits(7733,8125,8137,8139)
fly(7823,"Ratchet"); visit(3497)
visit(8696,"По дороге Barrens иди на юг к входу Razorfen Downs. Henry Stern внутри, проверяется обучающий gossip Goldthorn Tea. При отсутствии группы можно оставить 'Позже'; посещение входа ничего не подтверждает.")
travel("The Barrens",1413,50,78,"Дорога в Dustwallow Marsh","Вернись к развилке дороги севернее Razorfen Downs и следуй на восток в Dustwallow Marsh, затем по дороге в Theramore.")
visits(4894,4897)
travel("Dustwallow Marsh",1445,71.5,56.4,"Корабль в Менетил","Сядь на корабль Theramore → Menethil Harbor. Отметь после прибытия; между континентами стрелка может скрываться.")
note("*Восточные королевства.* Менетил → Loch Modan / Badlands → Arathi → Hinterlands → Southshore → Ironforge → Stormwind и южные зоны.")
visits(2094,3178,1078)
travel("Wetlands",1437,53.8,70.4,"Dun Algaz","По дороге через тоннели Dun Algaz войди в Loch Modan.")
visits(1684,1963,1465,1154,2817)
fly(1572,"Refuge Pointe"); visits(2810,2814)
fly(2835,"Aerie Peak"); visit(4782)
fly(8018,"Southshore"); visits(2381,2382,2430,2383)
travel("Hillsbrad Foothills",1424,75.3,24.8,"Тропа в Ravenholdt — Rogue","Следуй через пещеру к Ravenholdt; прямая стрелка через горы не является дорогой.","Rogue")
visit(6779)
fly(2432,"Ironforge"); visits(5162,5159,5160)
visit(1355,"Выйди из Ironforge и по дороге направляйся на восток Dun Morogh к Cook Ghilm.")
visits(1699,1267,8508)
fly(1573,"Stormwind"); visits(5494,340,5482,5483,332)
visits(66,1430)
travel("Elwynn Forest",1429,92.5,72.4,"Дорога в Redridge","От Goldshire следуй по дороге на восток, через Eastvale в Redridge Mountains.")
visits(343,3087,3085,381)
fly(931,"Darkshire"); visit(272)
fly(2409,"Rebel Camp"); visit(734,"После полёта открой меню NPC в Rebel Camp.")
fly(24366,"Westfall")
visits(235,7024,4305)
fly(523,"Booty Bay"); visit(2664)
note("*Камень в Шаттрат.* Вернись Hearthstone к Shaarubo; отметь после загрузки. Если перезарядка ещё идёт, дождись её.")
visit(25580,"Съезди к Old Man Barlo к северу от Шаттрата. Проверь fishing daily; рецепты в Bag of Fishing Treasures требуют фактического loot, не просто награды-ящика.")
fly(18940,"Honor Hold"); visits(16826,18987,19344)
fly(16822,"Wildhammer Stronghold"); visit(19369)
fly(18939,"Allerian Stronghold"); visits(19038,19296)
fly(18809,"Telaar"); visit(20096)
fly(18789,"Toshley's Station"); visit(21113)
fly(21107,"Evergrove"); visit(20916)
fly(22216,"Telredor"); visits(18993,18911)
fly(18788,"Orebor Harborage"); visits(20028,18382)
note("*Основной обход завершён.* /ctriage report покажет совпадения и расхождения отдельно для уверенной и сомнительной групп. Проверь непроверенные строки. /ctriage finish завершает пробег; затем /reload сохраняет данные на диск. Сезонные точки — Deferred Sources, цветовые пороги — Skill Breakpoint Checks.")
addon.mainRouteLength = #route

note("*Отложенные источники.* Этот раздел не образует непрерывный маршрут. Выбирай точку, когда выполнены её условия; TomTom ведёт к выбранному месту. Не записывай сезонное отсутствие как опровержение.")
local deferred = {}
for id, node in pairs(addon.nodes) do if node.deferred then deferred[#deferred + 1] = id end end
table.sort(deferred)
for _, id in ipairs(deferred) do visit(id, addon.nodes[id].deferred .. ". Если координат нет, найди NPC по имени; результат можно отметить через /ctriage npc " .. id .. ".") end
note("Для случайных источников и стартовых рецептов нет гарантированной точки меню. /ctriage deferred открывает их список. Подтверждай фактический источник с пояснением, а не наличие изученного рецепта или предмета в кэше.")
