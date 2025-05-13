Config = {}

Config.Debug = true
Config.ShowNotifications = true
Config.DetonateRange = 25.0
Config.DetonateKey = 47
Config.InstallTime = 8000
Config.DetectionRange = 5.0
Config.BombItem = 'vehiclebomb'

Config.ExplosionType = 4
Config.ExplosionDamage = 60.0
Config.ExplosionShake = 1.0
Config.FireEffect = true

Config.Animation = {
    dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
    name = "machinic_loop_mechandplayer",
    flag = 1
}

Config.UI = {
    width = 0.14,
    height = 0.075,
    borderThickness = 0.003,
    font = 4,
    scale = 0.45,
    position = "right",
    backgroundColor = {0, 0, 0, 180},
    textColor = {255, 255, 255, 255},
    borderColor = {255, 0, 0, 255},
    showKey = true,
    keyText = "G",
    blinking = false,
    blinkSpeed = 500,
    useGlowEffect = false,
    glowColor = {255, 0, 0, 50},
    glowSize = 0.003,
    useBlur = false,
    style = "classic",
    rtlText = true
}

Config.Text = {
    alreadyBombed = "רכב זה כבר מכיל פצצה",
    tooFar = "אתה צריך להיות קרוב יותר לרכב",
    startInstall = "מתחיל להתקין פצצה...",
    installing = "מתקין פצצה...",
    installCancelled = "התקנת הפצצה בוטלה",
    installed = "הפצצה הותקנה בהצלחה",
    detonated = "הפצצה פוצצה בהצלחה",
    noVehicle = "אין רכב בקרבת מקום",
    pressToDetonate = "לחץ על G כדי לפוצץ"
}