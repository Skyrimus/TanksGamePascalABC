program TankGame;

// Используемые пространства имен
uses
System.Threading, System.Windows, System.Windows.Forms, System.Windows.Input, GraphWPF, WPFObjects, System, Timers, System.Windows.Controls;

// Константы
const
  CooldownTime: Integer = 700; // Время перезарядки в миллисекундах
  TankImageSize = 50; // Размер изображения танка
  ScreenWidth = 800; // Ширина экрана
  ScreenHeight = 600; // Высота экрана
  TankSize = 50; // Размер танка
  MaxHP = 3; // Максимальное количество очков здоровья
  BulletSize = 40; // Размер пули
  BulletSpeed = 25; // Скорость пули
  MoveSpeed = 4; // Скорость перемещения
  RotateSpeed = 3; // Скорость поворота
  VK_A = 44; // Код клавиши "A"
  VK_D = 47; // Код клавиши "D"
  VK_W = 66; // Код клавиши "W"
  VK_S = 62; // Код клавиши "S"
  VK_SPACE = 18; // Код клавиши "Пробел"
  VK_LEFT = 23; // Код клавиши "Стрелка влево"
  VK_RIGHT = 25; // Код клавиши "Стрелка вправо"
  VK_UP = 24; // Код клавиши "Стрелка вверх"
  VK_DOWN = 26; // Код клавиши "Стрелка вниз"
  VK_RETURN = 6; // Код клавиши "Enter"


type
  Tank = record
    Name: string; // Имя танка
    X, LastX: Integer; // Координата X и предыдущая координата X
    Y, LastY: Integer; // Координата Y и предыдущая координата Y
    HP: Integer; // Очки здоровья танка
    CurrentColor: Color; // Текущий цвет танка
    Direction: Integer; // Направление танка
    Image: PictureWPF; // Изображение танка
    ImageFile: string; // Путь к файлу изображения танка
    LastShotTime: DateTime; // Время последнего выстрела
    CollidedWith: string; // Имя объекта, с которым танк столкнулся
  end;
  
  Bullet = record
    Tank: Tank; // Танк, из которого выстрелили пулей
    X: Integer; // Координата X пули
    Y: Integer; // Координата Y пули
    Speed: Integer; // Скорость пули
    Active: Boolean; // Флаг активности пули
    Image: PictureWPF; // Изображение пули
    Direction: Integer; // Направление пули
    CollidedWith: string = 'None'; // Имя объекта, с которым пуля столкнулась
  end;
  
  Wall = record
    X: Integer; // Координата X стены
    Y: Integer; // Координата Y стены
    Image: PictureWPF; // Изображение стены
  end;

type TPoint = record
  x, y: double; // Координаты точки
end;

type
  TanksArray = array of Tank; // Массив танков

var
  walls: array of Wall; // Массив стен
  Bullets: array of Bullet; // Массив пуль
  tanks: array of Tank; // Массив танков
  keysPressed: array[0..255] of Boolean; // Массив для отслеживания нажатых клавиш
  DebugOutput: string; // Переменная для хранения отладочного вывода
  Player1, Player2: Tank; // Игрок 1 и игрок 2
  Player1Image: PictureWPF; // Изображение игрока 1
  Player2Image: PictureWPF; // Изображение игрока 2
  Player1CenterX, Player1CenterY: Integer; // Координаты центра игрока 1
  PvEMode: Boolean; // Флаг режима PvE (игрок против компьютера)
  GameStarted: Boolean; // Флаг начала игры
  GamePaused: Boolean; // Флаг приостановки игры

procedure LoadImages(var tank: Tank);
begin
  // Создание изображения танка с использованием библиотеки PictureWPF
  tank.Image := PictureWPF.Create(-100,-100, tank.ImageFile);

  // Установка высоты и ширины изображения танка
  tank.Image.Height := TankSize;
  tank.Image.Width := TankSize;
end;

procedure AddWall(x: Integer; y: Integer; orientation: Integer);
var 
  newWall: Wall;
begin
  // Получение текущей длины массива стен
  var currentLength := Length(walls);

  // Создание нового объекта стены
  newWall := new Wall;

  // Создание изображения стены с использованием библиотеки PictureWPF
  newWall.Image := PictureWPF.Create(0,0, 'wall.png');

  // Установка высоты и ширины изображения стены
  newWall.Image.Height := 50;
  newWall.Image.Width := 50;

  // Установка координат X и Y для стены
  newWall.X := x;
  newWall.Y := y;

  // Установка угла поворота изображения стены
  newWall.Image.RotateAngle := orientation;

  // Перемещение изображения стены в указанные координаты X и Y
  newWall.Image.MoveTo(x, y);

  // Увеличение размера массива стен на один элемент
  SetLength(walls, currentLength + 1);

  // Присвоение новой стены последнему элементу массива стен
  walls[currentLength] := newWall;
end;

procedure LoadBullet(var bullet: Bullet);
begin
  // Создание изображения пули с использованием библиотеки PictureWPF
  bullet.Image := PictureWPF.Create(0, 0, 'bullet.png');

  // Скрытие изображения пули
  bullet.Image.Visible := False;

  // Установка высоты и ширины изображения пули
  bullet.Image.Height := BulletSize;
  bullet.Image.Width := BulletSize - 20;
end;

procedure DebugWriteLn(const Str: string);
begin
  // Добавление отладочной строки в переменную DebugOutput с переводом строки
  DebugOutput := DebugOutput + Str + #13#10;
end;

procedure DrawDebugOutput();
begin
  // Вывод отладочной строки на экран
  TextOut(10, 10, DebugOutput);
end;

procedure AddTank(tank: Tank);
begin
  // Получение текущей длины массива танков
  var currentLength := Length(tanks);

  // Увеличение размера массива танков на один элемент
  SetLength(tanks, currentLength + 1);

  // Присвоение нового танка последнему элементу массива танков
  tanks[currentLength] := tank;
end;

procedure AddBullet(bullet: Bullet);
begin
  // Получение текущей длины массива пуль
  var currentLength := Length(Bullets);

  // Увеличение размера массива пуль на один элемент
  SetLength(Bullets, currentLength + 1);

  // Присвоение новой пули последнему элементу массива пуль
  Bullets[currentLength] := bullet;
end;

function DeleteBullet(var arr: array of Bullet; element: Bullet): Boolean;
var
  i: Integer;
begin
  // Поиск указанного элемента в массиве пуль
  for i := Low(arr) to High(arr) do
  begin
    if arr[i] = element then
    begin
      // Сдвиг всех элементов после найденного элемента влево
      for var j := i to High(arr) - 1 do
        arr[j] := arr[j + 1];

      // Уменьшение размера массива пуль на один элемент
      SetLength(arr, Length(arr) - 1);

      Exit();
    end;
  end;

  // Если элемент не найден, возвращается False
  Result := False;
end;

function IsElementExistsByIndex(const arr: array of Bullet; index: Integer): Boolean;
begin
  // Проверка, существует ли элемент в массиве пуль по указанному индексу
  Result := (index >= Low(arr)) and (index <= High(arr));
end;

function ifWallExists(const arr: array of Wall; index: Integer): Boolean;
begin
  // Проверка, существует ли стена в массиве стен по указанному индексу
  Result := (index >= Low(arr)) and (index <= High(arr));
end;

procedure TPTank(var tank: Tank; x,y,dir: Integer);
begin
  // Установка начального значения здоровья танка
  tank.HP := 3;

  // Отображение изображения танка
  tank.Image.Visible := True;

  // Установка координат X и Y для танка
  tank.X := x;
  tank.Y := y;

  // Установка направления танка
  tank.Direction := dir;
end;

procedure RandomSpawn();
var
  randomNumberPlayer, randomNumberBot: Integer;
  randomGeneratorPlayer: System.Random;
  randomGeneratorBot: System.Random;
begin
  // Создание объектов генератора случайных чисел для игрока и бота
  randomGeneratorPlayer := System.Random.Create;
  randomGeneratorBot := System.Random.Create;

  // Генерация случайных чисел для определения координаты Y игрока и бота
  randomNumberPlayer := randomGeneratorPlayer.Next(600);
  randomNumberBot := randomGeneratorBot.Next(600);
  
  // Создание и размещение танков игрока и бота на случайных позициях
  TPTank(Player1, 100, Round(randomNumberPlayer), 90);
  TPTank(Player2, ScreenWidth - 100, Round(randomNumberBot), 180);
end;

procedure Level1();
begin
  // Случайная генерация позиций танков игрока и бота
  RandomSpawn();

  // Очистка массива стен
  SetLength(walls, 0);

  // Скрытие изображений пуль
  for var i := 0 to High(Bullets) do
  begin
    Bullets[i].Image.Visible := False;
  end;

  // Очистка массива пуль
  SetLength(Bullets, 0);

  // Добавление стен для уровня 1
  AddWall(200, 0, 0); 
  AddWall(200, 50, 0);
  AddWall(200, 100, 0);
  AddWall(200, 150, 0);
  AddWall(200, 200, 0);
  AddWall(400, 0, 0); 
  AddWall(400, 50, 0);
  AddWall(400, 100, 0);
  AddWall(400, 150, 0);
  AddWall(400, 200, 0);
  /////////////////////
  AddWall(200, 510, 0);
  AddWall(200, 410, 0);
  AddWall(200, 460, 0);
  AddWall(200, 560, 0);
  AddWall(400, 410, 0);
  AddWall(400, 460, 0);
  AddWall(400, 510, 0);
  AddWall(400, 560, 0);

  // Установка флага паузы игры в False
  GamePaused := False;
end;

procedure Level2();
begin
  // Установка позиций танков игрока и бота для уровня 2
  TPTank(Player1, ScreenWidth div 2 - 50, ScreenHeight div 2 + 250, -90);
  TPTank(Player2, ScreenWidth div 2 - 50, ScreenHeight div 2 - 290, 90);

  // Очистка массива стен
  SetLength(walls, 0);

  // Скрытие изображений пуль
  for var i := 0 to High(Bullets) do
  begin
    Bullets[i].Image.Visible := False;
  end;

  // Очистка массива пуль
  SetLength(Bullets, 0);

  // Добавление стен для уровня 2
  AddWall(75, 70, 0);
  AddWall(190, 70, 0);
  AddWall(305, 70, 0);
  AddWall(355, 70, 0);
  AddWall(405, 70, 0);
  //AddWall(450, 70, 0);
  AddWall(515, 70, 0);
  AddWall(620, 70, 0);
  ///////
  AddWall(75, 120, 0);
  AddWall(190, 120, 0);
  // AddWall(305,120, 0);
  // AddWall(355,120, 0);
  // AddWall(405,120, 0);
  // AddWall(450,120, 0);
  AddWall(515, 120, 0);
  AddWall(620, 120, 0);
  ///////
  AddWall(75, 490, 0);
  AddWall(190, 490, 0);
  AddWall(305, 490, 0);
  AddWall(355, 490, 0);
  AddWall(405, 490, 0);
  AddWall(515, 490, 0);
  AddWall(620, 490, 0);
  ///////
  AddWall(75, 120, 0);
  AddWall(190, 120, 0);
  AddWall(515, 120, 0);
  AddWall(620, 120, 0);
  
  AddWall(75, 440, 0);
  AddWall(190, 440, 0);

  AddWall(515, 440, 0);
  AddWall(620, 440, 0);
  ///////
  AddWall(75, 280, 0);
  AddWall(125, 280, 0);
  AddWall(175, 280, 0);
  AddWall(225, 280, 0);
  AddWall(275, 280, 0);
  AddWall(325, 280, 0);
  AddWall(375, 280, 0);
  AddWall(425, 280, 0);
  AddWall(475, 280, 0);
  AddWall(525, 280, 0);
  AddWall(575, 280, 0);
  AddWall(625, 280, 0);

  // Установка флага паузы игры в False
  GamePaused := False;
end;
procedure InitializeGame;
var
  tick: DateTime;
begin
  Randomize;

  // Установка заголовка окна игры
  GraphWPF.Window.Title := 'Tank Game';

  // Установка размера окна игры
  GraphWPF.Window.SetSize(ScreenWidth, ScreenHeight);

  // Центрирование окна на экране
  GraphWPF.Window.CenterOnScreen;

  // Установка фиксированного размера окна
  GraphWPF.Window.IsFixedSize := True;

  // Установка шрифта
  Font.Name := 'Courier New';
 // Font.Style := Bold;
  Font.Size := 15;

  // Установка изображений и имён игроков
  Player1.ImageFile := 'tank_red.png';
  Player2.ImageFile := 'tank_blue.png';
  Player1.Name := 'Player1';
  Player2.Name := 'Player2';

  // Установка времени последнего выстрела для обоих игроков
  tick := DateTime.Now;
  Player1.LastShotTime := tick;
  Player2.LastShotTime := tick;

  // Установка начальной позиции, жизней и направления для игрока 1
  Player1.X := 100;
  Player1.Y := ScreenHeight div 2;
  Player1.HP := MaxHP;
  Player1.Direction := 0;

  // Установка начальной позиции, жизней и направления для игрока 2
  Player2.X := ScreenWidth - 100;
  Player2.Y := ScreenHeight div 2;
  Player2.HP := MaxHP;
  Player2.Direction := 180;

  // Установка режима игры и флагов состояния
  PvEMode := False;
  GameStarted := False;
  GamePaused := False;

  // Загрузка изображений для игроков
  LoadImages(Player1);
  LoadImages(Player2);

  // Добавление игроков на поле
  AddTank(Player1);
  AddTank(Player2);
end;

procedure DrawTanksImages;
begin
  // Позиционирование и поворот изображений танков игроков
  Player1.Image.MoveTo(Player1.X, Player1.Y);
  Player1.Image.RotateAngle := Player1.Direction - 90;

  Player2.Image.MoveTo(Player2.X, Player2.Y);
  Player2.Image.RotateAngle := Player2.Direction - 90;
end;

procedure DrawBullet(bullet: Bullet);
var
  bulletSizeHalf: Integer;
begin
  // Проверка активности пули
  if bullet.Active = True then
  begin
    // Отображение пули на поле
    bullet.Image.Visible := True;
    bullet.Image.MoveTo(bullet.X, bullet.Y);
    bullet.Image.RotateAngle := bullet.Direction + 90;
  end
  else
  begin
    // Скрытие пули
    bullet.Image.Visible := False;
  end;
end;

procedure DrawBullets;
begin
  // Отрисовка всех пуль на поле
  for var i := 0 to High(Bullets) do
    DrawBullet(Bullets[i]);
end;

procedure Shoot(tank: Tank);
var
  CurrentTime: DateTime;
  TimeDifference: TimeSpan;
  bullet: Bullet;
begin
  CurrentTime := DateTime.Now;
  TimeDifference := CurrentTime - tank.LastShotTime;

  // Проверка прошедшего времени с момента последнего выстрела
  if TimeDifference.TotalMilliseconds >= CooldownTime then
  begin
    // Создание пули и установка её параметров
    bullet.Tank := tank;
    LoadBullet(bullet);
    bullet.X := tank.X + Ceil(TankSize / 2);
    bullet.Y := tank.Y;

    bullet.CollidedWith := bullet.Tank.Name;

    bullet.Direction := tank.Direction;
    bullet.Speed := BulletSpeed;
    bullet.Active := True;

    // Добавление пули на поле
    AddBullet(bullet);

    writeln('shooted');
    tank.LastShotTime := CurrentTime;
  end;
end;

procedure DrawMenu();
var
  MenuWidth, MenuHeight: Integer;
  MenuX, MenuY: Integer;
begin
  // Задание размеров и позиции меню
  MenuWidth := 300;
  MenuHeight := 200;
  MenuX := (ScreenWidth - MenuWidth) div 2;
  MenuY := (ScreenHeight - MenuHeight) div 2;

  // Очистка окна
  GraphWPF.Window.Clear();

  // Установка шрифта, кисти и пера
  Font.Size := 24;
  Font.Color := Color.FromRgb(0, 0, 0);
  Brush.Color := Color.FromRgb(255, 255, 255);
  Pen.Color := Color.FromRgb(0, 0, 0);

  // Отображение заголовка меню
  Font.Size := 24;
  Font.Color := Color.FromRgb(0, 0, 0);
  TextOut(MenuX + (MenuWidth - Integer(TextWidth('TANK GAME'))) div 2, MenuY + 50, 'TANK GAME');

  // Отображение текста выбора режима игры
  Font.Size := 20;
  TextOut(MenuX + (MenuWidth - Integer(TextWidth('Choose a game mode:'))) div 2, MenuY + 100, 'Choose a game mode:');
  TextOut(MenuX + (MenuWidth - Integer(TextWidth('F1. PVE Mode'))) div 2, MenuY + 150, 'F1. PVE Mode');
  TextOut(MenuX + (MenuWidth - Integer(TextWidth('F2. PVP Mode'))) div 2, MenuY + 180, 'F2. PVP Mode');

  // Задержка для отображения меню
  sleep(2000);

  // Очистка окна
  GraphWPF.Window.Clear();
end;

procedure Win(player: string);
var
  MenuWidth, MenuHeight: Integer;
  MenuX, MenuY: Integer;
begin
  // Задание размеров и позиции окна победы
  MenuWidth := 300;
  MenuHeight := 200;
  MenuX := (ScreenWidth - MenuWidth) div 2;
  MenuY := (ScreenHeight - MenuHeight) div 2;

  // Очистка окна
  GraphWPF.Window.Clear();

  // Установка шрифта, кисти и пера
  Font.Size := 24;
  Font.Color := Color.FromRgb(0, 0, 0);
  Brush.Color := Color.FromRgb(255, 255, 255);
  Pen.Color := Color.FromRgb(0, 0, 0);

  // Отображение сообщения о победе игрока
  Font.Size := 24;
  Font.Color := Color.FromRgb(0, 0, 0);
  TextOut(MenuX + (MenuWidth - Integer(TextWidth(player + ' wins!'))) div 2, MenuY + 50, player + ' wins!');

  // Задержка для отображения сообщения о победе
  sleep(3000);

  // Очистка окна
  GraphWPF.Window.Clear();
end;
procedure HandleMenuInput(Key: System.Windows.Input.Key);
begin
  // Обработка ввода пользователя в меню
  case Key of
    System.Windows.Input.Key.F1:
    begin
      PvEMode := True;
      GameStarted := True;
      Level1();
    end;
    System.Windows.Input.Key.F2:
    begin
      PvEMode := False;
      GameStarted := True;
      Level2();
    end;
  end;
end;

function Distance(x1, y1, x2, y2: Integer): Double;
begin
  // Расчет расстояния между двумя точками
  Result := Sqrt(Sqr(x2 - x1) + Sqr(y2 - y1));
end;

procedure RotateTank(var tank: Tank; angle: Integer);
begin
  // Поворот танка на заданный угол
  tank.Direction := (tank.Direction + angle) mod 360;
end;

function CheckCollision(x1, y1, size1, x2, y2, size2: Integer): Boolean;
begin
  // Проверка на столкновение двух объектов
  Result := (x1 < x2 + size2) and
            (x1 + size1 > x2) and
            (y1 < y2 + size2) and
            (y1 + size1 > y2);
end;

function CheckCollisionWithTanks(tank: Tank; newTankX, newTankY: Integer): Boolean;
var
  i: Integer;
begin  
  // Проверка на столкновение с другими танками
  if (tank <> Player2) then
  begin
    if CheckCollision(newTankX, newTankY, TankSize, Player2.X, Player2.Y, TankSize) then
    begin         
      Result := True;
      Exit;
    end;
  end;
  if (tank <> Player1) then
  begin
    if CheckCollision(newTankX, newTankY, TankSize, Player1.X, Player1.Y, TankSize) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

procedure ReloadLevel(player: string);
begin
  // Перезагрузка уровня после победы одного из игроков
  Win(player);
  GamePaused := True;
  if PvEMode then
    Level1()
  else
    Level2();
end;

function BulletCollisionWithTanks(var bullet: Bullet; newTankX, newTankY: Integer): Boolean;
var
  i: Integer;
begin
  // Проверка на столкновение пули с танками
  if (bullet.Tank <> Player2) then
  begin
    if CheckCollision(newTankX, newTankY, TankSize, Player2.X, Player2.Y, TankSize) then
    begin
      if Player2.HP = 1 then
      begin
        writeln('Player2 destroyed');
        Player2.Image.Visible := False;
        ReloadLevel('Player1');
        Result := True;
        Exit;
      end;
      writeln('collided with player2');
      bullet.CollidedWith := 'Player2';  
      Player2.HP := Player2.HP - 1;
      writeln('Player2 HP = ' + Player2.HP);
      Result := True;
      Exit;
    end;
  end;
  if (bullet.Tank <> Player1) then
  begin
    if CheckCollision(newTankX, newTankY, TankSize, Player1.X, Player1.Y, TankSize) then
    begin
      if Player1.HP = 1 then
      begin
        writeln('Player1 destroyed');
        Player1.Image.Visible := False;
        ReloadLevel('Player2');
        Result := True;
        Exit;
      end;
      writeln('collided with player1');
      bullet.CollidedWith := 'Player1';
      Player1.HP := Player1.HP - 1;
      writeln('Player1 HP = ' + Player1.HP);
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function CheckCollisionWithWalls(tank: Tank; newTankX, newTankY: Integer): Boolean;
var
  i: Integer;
begin  
  // Проверка на столкновение с преградами
  for i := 0 to High(walls) do
  begin
    if CheckCollision(newTankX, newTankY, Integer(walls[i].Image.Width), walls[i].X, walls[i].Y, Integer(walls[i].Image.Height)) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function BulletCollisionWithWalls(bullet: Bullet; newTankX, newTankY: Integer): Boolean;
var
  i: Integer;
begin  
  // Проверка на столкновение пули с преградами
  for i := 0 to High(walls) do
  begin
    if CheckCollision(newTankX, newTankY, Integer(walls[i].Image.Width), walls[i].X, walls[i].Y, Integer(walls[i].Image.Height)) then
    begin   
      writeln('collided with wall by bullet');
      bullet.CollidedWith := 'Wall';
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

procedure MoveTank(var tank: Tank; dir: string);
var
  newPosX, newPosY: Integer;
begin
  // Проверка наличия паузы в игре
  if GamePaused = False then
  begin
    // Проверка направления движения танка
    if dir = 'Forward' then
    begin
      // Вычисление новой позиции танка при движении вперед
      newPosX := tank.X + Round(MoveSpeed * Cos(DegToRad(tank.Direction)));
      newPosY := tank.Y + Round(MoveSpeed * Sin(DegToRad(tank.Direction)));
    end
    else if dir = 'Back' then
    begin
      // Вычисление новой позиции танка при движении назад
      newPosX := tank.X - Round(MoveSpeed * Cos(DegToRad(tank.Direction)));
      newPosY := tank.Y - Round(MoveSpeed * Sin(DegToRad(tank.Direction)));
    end;

    // Проверка возможности перемещения танка на новую позицию
    if (newPosX >= 0) and (newPosX <= ScreenWidth) and (newPosY >= 0) and (newPosY <= ScreenHeight) and
       (CheckCollisionWithTanks(tank, newPosX, newPosY) <> True) and
       (CheckCollisionWithWalls(tank, newPosX, newPosY) <> True) then
    begin
      tank.X := newPosX;
      tank.Y := newPosY;
    end;
  end;
end;

procedure MoveBullet(var bullet: Bullet);
var
  newPosX, newPosY, direction: Integer;
begin
  // Проверка активности пули и отсутствия паузы в игре
  if (bullet.Active = True) and (GamePaused = False) then
  begin
    direction := bullet.Tank.Direction;
    // Вычисление новой позиции пули при движении
    newPosX := bullet.X + Round(BulletSpeed * Cos(DegToRad(direction)));
    newPosY := bullet.Y + Round(BulletSpeed * Sin(DegToRad(direction)));

    // Проверка возможности перемещения пули на новую позицию
    if (newPosX >= 0) and (newPosX <= ScreenWidth) and (newPosY >= 0) and (newPosY <= ScreenHeight) and
       (BulletCollisionWithTanks(bullet, newPosX - 40, newPosY - 40) <> True) and
       (BulletCollisionWithWalls(bullet, newPosX, newPosY) <> True) then
    begin
      bullet.X := newPosX;
      bullet.Y := newPosY;
    end
    else
    begin
      // Обработка столкновения пули с другими объектами
      if (bullet.Tank.Name <> bullet.CollidedWith) and (bullet.CollidedWith <> 'Wall') then
      begin
        // Пуля попала в танк противника
        bullet.Active := False;
        bullet.Image.Visible := False;
        DeleteBullet(Bullets, bullet);
      end
      else
      begin
        // Пуля попала в стену
        bullet.Active := False;
        bullet.Image.Visible := False;
        DeleteBullet(Bullets, bullet);
      end;
    end;
  end;
end;

procedure KeyUpHandler(Key: System.Windows.Input.Key);
begin
  // Обработчик отпускания клавиши
  keysPressed[Integer(Key)] := False;
end;

procedure Update();
begin
  // Обновление игровой логики
  if keysPressed[VK_A] then
  begin        
    RotateTank(Player1, -RotateSpeed);
  end;
  if keysPressed[VK_D] then
    RotateTank(Player1, RotateSpeed);
  if keysPressed[VK_W] then
    MoveTank(Player1, 'Forward');
  if keysPressed[VK_S] then
    MoveTank(Player1, 'Back');
  if keysPressed[VK_LEFT] and not PvEMode then
    RotateTank(Player2, -5);
  if keysPressed[VK_RIGHT] and not PvEMode then
    RotateTank(Player2, 5);
  if keysPressed[VK_UP] and not PvEMode then
    MoveTank(Player2, 'Forward');
  if keysPressed[VK_DOWN] and not PvEMode then
    MoveTank(Player2, 'Back');

  // Обновление положения пуль
  for var i := 0 to High(Bullets) do
  begin
    if IsElementExistsByIndex(Bullets, i) then
      MoveBullet(Bullets[i]);
  end;

  sleep(16); // Задержка для контроля частоты обновления
end;

// Процедура для обработки нажатия клавиш
procedure HandleKeyPresses(Key: System.Windows.Input.Key);
var
  NewX1, NewY1, NewX2, NewY2, keyCode: Integer;
begin
  // Получение кода нажатой клавиши
  keyCode := Integer(Key);
  
  // Проверка, была ли уже нажата клавиша
  if keysPressed[keyCode] then
    Exit;
    
  if keyCode = VK_SPACE then
  begin
    // Выстрел игрока 1
    Shoot(Player1);
  end;
  
  if (keyCode = VK_RETURN) and not PvEMode then
  begin
    // Выстрел игрока 2
    Shoot(Player2);
  end;
  
  // Установка флага, что клавиша была нажата
  keysPressed[keyCode] := True;
end;

// Функция для вычисления угла между двумя точками
function GetAngle(x1, y1, x2, y2: Integer): Double;
var
  dx, dy: Integer;
begin
  // Вычисление разности координат по осям X и Y
  dx := x2 - x1;
  dy := y2 - y1;
  
  // Вычисление угла в градусах с помощью арктангенса
  Result := RadToDeg(ArcTan(dy / dx));
  
  // Корректировка угла в зависимости от четверти координатной плоскости
  if dx < 0 then
    Result := Result + 180
  else if (dx >= 0) and (dy < 0) then
    Result := Result + 360;
end;

// Процедура для установки направления бота по направлению к игроку
procedure SetBotTankDirection(var botTank, playerTank: Tank);
var
  angle: Double;
begin
  // Вычисление угла между ботом и игроком
  angle := GetAngle(botTank.X, botTank.Y, playerTank.X, playerTank.Y);
  
  // Округление угла до целого значения и установка направления бота
  botTank.Direction := Round(angle);
end;

// Процедура для стрельбы бота
procedure BotShoot();
var
  randomNumber: Integer;
  randomGenerator: System.Random;
begin
  // Создание генератора случайных чисел
  randomGenerator := System.Random.Create;
  
  // Генерация случайного числа в диапазоне 0-149
  randomNumber := randomGenerator.Next(150);
  
  // Если сгенерированное число меньше или равно 1, бот стреляет
  if randomNumber <= 1 then
  begin
    Shoot(Player2);
  end;
end;

// Процедура для реализации искусственного интеллекта в режиме PvE
procedure PvETankAI;
var
  angle: Double;
begin
  // Вычисление центральной точки игрока 1
  Player1CenterX := Player1.X;
  Player1CenterY := Player1.Y;
  
  // Вычисление угла между ботом и центральной точкой игрока 1
  angle := GetAngle(Player2.X, Player2.Y, Player1CenterX, Player1CenterY);
  
  // Установка направления бота
  SetBotTankDirection(Player2, Player1);
  
  // Перемещение бота вперед
  MoveTank(Player2, 'Forward');
  
  // Выполнение выстрела ботом
  BotShoot();
  
  // Задержка для контроля частоты обновления
  Sleep(16);
end;

// Процедура для отрисовки игрового состояния
procedure DrawGame;
begin
  // Отрисовка отладочной информации
  DrawDebugOutput;
  
  // Отрисовка пуль
  DrawBullets;
  
  // Отрисовка изображений танков
  DrawTanksImages;
  
  // Если включен режим PvE, запуск искусственного интеллекта бота
  if PvEMode then
  begin
    PvETankAI;
  end;
end;

// Основной игровой цикл
procedure GameLoop;
begin
  repeat
    if GameStarted then
    begin
      // Установка обработчиков событий нажатия клавиш и отпускания клавиш
      OnKeyDown := HandleKeyPresses;
      OnKeyUp := KeyUpHandler;
      
      // Отрисовка игрового состояния
      DrawGame;
      
      // Обновление игровой логики
      Update;
    end
    else
    begin
      // Установка обработчика событий нажатия клавиш в меню
      OnKeyDown := HandleMenuInput;
      
      // Отрисовка меню
      DrawMenu;
    end;
  until false;
end;

begin
  // Инициализация игры
  InitializeGame;
  
  // Запуск игрового цикла
  GameLoop;
end.

