fx_version 'cerulean'
game 'gta5'

author 'zFabiSkills'
description 'Lotto Script'
version '1.0.0'

client_scripts {
    '@es_extended/imports.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', 
     '@es_extended/imports.lua',
    'server/main.lua'
}

shared_script {
    'config.lua',
}

files {
    'screen/index.html',
    'screen/script/index.js',
    'screen/style/style.css',
}

dependencies {
    'es_extended', 
    'oxmysql' 
}

ui_page 'screen/index.html'