function love.load()
    math.randomseed(os.time())

    GAMESTATE_MENU = 1
    GAMESTATE_PLAYING = 2

    sprites = {}
    sprites.background = love.graphics.newImage('assets/img/background.jpg')
    sprites.bullet = love.graphics.newImage('assets/img/bullet.png')
    sprites.player = love.graphics.newImage('assets/img/player.png')
    sprites.zombie = love.graphics.newImage('assets/img/zombie.png')
    sprites.heart = love.graphics.newImage('assets/img/heart.png')

    player = {}
    player.x = love.graphics.getWidth() / 2
    player.y = love.graphics.getHeight() / 2
    player.speed = 180
    
    startingLives = 3
    player.lives = startingLives

    myFont = love.graphics.newFont(30)

    zombies = {}
    bullets = {}

    gameState = GAMESTATE_MENU
    score = 0
    maxTime = 2
    timer = maxTime

    sounds = {}
    sounds.music = love.audio.newSource("assets/sounds/alexander-nakarada-metal.mp3", "stream")
    sounds.zombieHit = love.audio.newSource("assets/sounds/zombie-hit.mp3", "static")
    sounds.playerHit = love.audio.newSource("assets/sounds/player-hit.mp3", "static")
    sounds.music:play()
end

function love.update(dt)
    if gameState == GAMESTATE_PLAYING then
        if love.keyboard.isDown("d") and player.x < love.graphics.getWidth() - sprites.player:getWidth() / 2 then
            player.x = player.x + player.speed * dt
        end

        if love.keyboard.isDown("a") and player.x > 0 + sprites.player:getWidth() / 2 then
            player.x = player.x - player.speed * dt
        end
        
        if love.keyboard.isDown("w") and player.y > 0 + sprites.player:getHeight() / 2 then
            player.y = player.y - player.speed * dt
        end

        if love.keyboard.isDown("s") and player.y < love.graphics:getHeight() - sprites.player:getHeight() / 2 then
            player.y = player.y + player.speed * dt
        end
    end

    for i,z in ipairs(zombies) do
        z.x = z.x + (math.cos(zombiePlayerAngle(z)) * z.speed * dt)
        z.y = z.y + (math.sin(zombiePlayerAngle(z)) * z.speed * dt)

        if distanceBetween(z.x, z.y, player.x, player.y) < 30 then
            for i,z in ipairs(zombies) do
                zombies[i] = nil
            end

            player.lives = player.lives - 1
            sounds.playerHit:play()

            if player.lives == 0 then
                gameState = GAMESTATE_MENU
                player.lives = startingLives
                player.x = love.graphics.getWidth() / 2
                player.y = love.graphics.getHeight() / 2
            end
        end
    end

    for i,b in ipairs(bullets) do
        b.x = b.x + (math.cos(b.direction) * b.speed * dt)
        b.y = b.y + (math.sin(b.direction) * b.speed * dt)
    end

    for i,z in ipairs(zombies) do
        for j,b  in ipairs(bullets) do
            if distanceBetween(z.x, z.y, b.x, b.y) < 20 then
                z.dead = true
                b.dead = true
                score = score + 1
                sounds.zombieHit:play()
            end
        end
    end

    for i=#zombies, 1, -1 do
        local z = zombies[i]
        if z.dead then
            table.remove(zombies, i)
        end
    end

    for i=#bullets, 1, -1 do
        local b = bullets[i]
        if b.dead then
            table.remove(bullets, i)
        end
    end

    if gameState == GAMESTATE_PLAYING then
        timer = timer - dt
        if timer <= 0 then
            spawnZombie()
            maxTime = 0.95 * maxTime
            timer = maxTime
        end
    end
end

function love.draw()
    love.graphics.draw(sprites.background, 0, 0)

    if gameState == GAMESTATE_MENU then
        love.graphics.setFont(myFont)
        love.graphics.printf("Click anywhere to begin!", 0, 50, love.graphics.getWidth(), "center")
    end

    love.graphics.printf("Score: " .. score, 0, love.graphics.getHeight() - 100, love.graphics.getWidth(), "center")

    for i = 1, startingLives, 1 do
        if i > player.lives then
            love.graphics.setColor(1, 1, 1, 0.1)
        end
        love.graphics.draw(sprites.heart, sprites.heart:getWidth() * i, 50, nil, .5, nil, sprites.heart:getWidth(), sprites.heart:getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), nil, nil, sprites.player:getWidth() / 2, sprites.player:getHeight() / 2)

    for i,z in ipairs(zombies) do
        love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, sprites.zombie:getWidth() / 2, sprites.zombie:getHeight() / 2)
    end

    for i,b in ipairs(bullets) do
        love.graphics.draw(sprites.bullet, b.x, b.y, nil, .5, nil, sprites.bullet:getWidth() / 2, sprites.bullet:getHeight() / 2)
    end

    for i=#bullets, 1, -1 do
        local b = bullets[i]
        if b.x < 0 or b.y < 0 or b.x > love.graphics.getWidth() or b.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and gameState == GAMESTATE_PLAYING then
        spawnBullet()
    elseif button == 1 and gameState == GAMESTATE_MENU then
        gameState = GAMESTATE_PLAYING
        maxTime = 2
        timer = maxTime
        score = 0
    end
end

function playerMouseAngle()
    return math.atan2(player.y - love.mouse.getY(), player.x - love.mouse.getX()) + math.pi
end

function zombiePlayerAngle(enemy)
    return math.atan2(player.y - enemy.y, player.x - enemy.x)
end

function spawnZombie()
    local zombie = {}
    zombie.x = 0
    zombie.y = 0
    zombie.speed = 140
    zombie.dead = false

    local side = math.random(1, 4)

    if side == 1 then
        zombie.x = -30
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif side == 2 then
        zombie.x = love.graphics.getWidth() + 30
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif side == 3 then
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = -30
    elseif side == 4 then
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = love.graphics.getHeight() + 30
    end
    
    table.insert(zombies, zombie)
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function spawnBullet()
    local bullet = {}
    bullet.x = player.x
    bullet.y = player.y
    bullet.speed = 500
    bullet.dead = false
    bullet.direction = playerMouseAngle()
    table.insert(bullets, bullet)
end
